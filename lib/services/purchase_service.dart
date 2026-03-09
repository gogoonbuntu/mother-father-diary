import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 인앱 결제 서비스 — 프리미엄 구독 관리
class PurchaseService extends ChangeNotifier {
  static final PurchaseService _instance = PurchaseService._();
  factory PurchaseService() => _instance;
  PurchaseService._();

  // ── 상품 ID ──────────────────────────────
  static const String monthlyId = 'premium_monthly';
  static const String yearlyId  = 'premium_yearly';
  static const String lifetimeId = 'premium_lifetime';

  static const Set<String> _productIds = {monthlyId, yearlyId, lifetimeId};

  // ── 상태 ──────────────────────────────────
  bool _available = false;
  bool _isPremium = false;
  bool _loading = false;
  List<ProductDetails> _products = [];
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool get isPremium => _isPremium;
  bool get isAvailable => _available;
  bool get isLoading => _loading;
  List<ProductDetails> get products => _products;

  // ── 초기화 ────────────────────────────────
  Future<void> initialize() async {
    // 로컬 캐시 먼저 로드
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool('isPremium') ?? false;
    notifyListeners();

    final isStoreAvailable = await InAppPurchase.instance.isAvailable().catchError((_) => false);
    _available = isStoreAvailable;

    if (!isStoreAvailable) {
      debugPrint('[IAP] 스토어 사용 불가');
      return;
    }

    // 구매 업데이트 스트림 구독
    _subscription = InAppPurchase.instance.purchaseStream.listen(
      _onPurchaseUpdated,
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('[IAP] 스트림 에러: $error'),
    );

    // 상품 정보 로드
    await _loadProducts();

    // 미처리 구매 확인 (앱 재시작 시 필요)
    await _restorePurchases();
  }

  Future<void> _loadProducts() async {
    _loading = true;
    notifyListeners();

    final response = await InAppPurchase.instance.queryProductDetails(_productIds);
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('[IAP] 상품 못 찾음: ${response.notFoundIDs}');
    }
    _products = response.productDetails;
    _products.sort((a, b) {
      // 월간 → 연간 → 평생 순
      const order = {monthlyId: 0, yearlyId: 1, lifetimeId: 2};
      return (order[a.id] ?? 3).compareTo(order[b.id] ?? 3);
    });

    _loading = false;
    notifyListeners();
  }

  // ── 구매 ──────────────────────────────────
  Future<bool> buyProduct(ProductDetails product) async {
    if (!_available) return false;

    final purchaseParam = PurchaseParam(productDetails: product);
    
    if (product.id == lifetimeId) {
      // 평생 이용권 = 비소모성 상품
      return InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      // 월간/연간 = 구독
      return InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  // ── 복원 ──────────────────────────────────
  Future<void> _restorePurchases() async {
    await InAppPurchase.instance.restorePurchases();
  }

  Future<void> restorePurchases() async {
    _loading = true;
    notifyListeners();
    await InAppPurchase.instance.restorePurchases();
    // 결과는 purchaseStream을 통해 전달됨
    await Future.delayed(const Duration(seconds: 3));
    _loading = false;
    notifyListeners();
  }

  // ── 구매 업데이트 처리 ────────────────────
  void _onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _verifyAndActivate(purchase);
          break;
        case PurchaseStatus.error:
          debugPrint('[IAP] 구매 에러: ${purchase.error?.message}');
          _loading = false;
          notifyListeners();
          break;
        case PurchaseStatus.pending:
          debugPrint('[IAP] 결제 대기 중...');
          break;
        case PurchaseStatus.canceled:
          debugPrint('[IAP] 구매 취소됨');
          _loading = false;
          notifyListeners();
          break;
      }
    }
  }

  Future<void> _verifyAndActivate(PurchaseDetails purchase) async {
    // pending transaction 완료 처리
    if (purchase.pendingCompletePurchase) {
      await InAppPurchase.instance.completePurchase(purchase);
    }

    // 프리미엄 활성화
    if (_productIds.contains(purchase.productID)) {
      _isPremium = true;
      _loading = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isPremium', true);
      await prefs.setString('premiumProductId', purchase.productID);
      await prefs.setString('premiumPurchaseDate', DateTime.now().toIso8601String());
      notifyListeners();
      debugPrint('[IAP] ✅ 프리미엄 활성화: ${purchase.productID}');
    }
  }

  // ── 상품 정보 헬퍼 ────────────────────────
  ProductDetails? getProduct(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 디버그용: 프리미엄 강제 전환
  Future<void> debugSetPremium(bool value) async {
    _isPremium = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPremium', value);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
