import 'package:flutter/material.dart';
import 'services/purchase_service.dart';

/// 프리미엄 구독 화면 — 3가지 플랜 (월간/연간/평생)
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final _purchaseService = PurchaseService();
  bool _restoring = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3EEFF), Color(0xFFFFF0F5), Color(0xFFEEF7FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── AppBar ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF5A3ED9)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _restoring ? null : _handleRestore,
                      child: Text(
                        '구매 복원',
                        style: TextStyle(
                          color: _restoring ? Colors.grey : const Color(0xFF7C5CFC),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── 본문 ──
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      // 아이콘 + 타이틀
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C5CFC), Color(0xFFFF8FAB)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C5CFC).withValues(alpha: 0.3),
                              blurRadius: 16, offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.diamond_rounded, size: 40, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '프리미엄 무제한',
                        style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w800,
                          color: Color(0xFF2D2D3A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'AI 일기 변환을 제한 없이 사용하세요',
                        style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 28),

                      // ── 혜택 목록 ──
                      _buildBenefitCard(),

                      const SizedBox(height: 24),

                      // ── 가격 카드 ──
                      _buildPlanCard(
                        title: '월간 구독',
                        price: '₩2,900',
                        period: '/ 월',
                        description: '언제든 해지 가능',
                        productId: PurchaseService.monthlyId,
                        isPopular: false,
                        gradient: const [Color(0xFFF0EBFF), Color(0xFFE8E0FF)],
                      ),
                      const SizedBox(height: 12),
                      _buildPlanCard(
                        title: '연간 구독',
                        price: '₩14,900',
                        period: '/ 년',
                        description: '월 ₩1,242 · 57% 절약',
                        productId: PurchaseService.yearlyId,
                        isPopular: true,
                        gradient: const [Color(0xFF7C5CFC), Color(0xFF9B7DFF)],
                      ),
                      const SizedBox(height: 12),
                      _buildPlanCard(
                        title: '평생 이용권',
                        price: '₩29,900',
                        period: '',
                        description: '한 번 결제로 영원히',
                        productId: PurchaseService.lifetimeId,
                        isPopular: false,
                        gradient: const [Color(0xFFFFF0F3), Color(0xFFFFE8ED)],
                      ),

                      const SizedBox(height: 24),

                      // ── 안내문 ──
                      Text(
                        '구독은 iTunes/Google Play 계정을 통해 결제되며,\n'
                        '자동 갱신을 히지 않으면 구독 기간 종료 24시간 전에\n'
                        '자동으로 갱신됩니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400, height: 1.5),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 혜택 카드 ──
  Widget _buildBenefitCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF7C5CFC).withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C5CFC).withValues(alpha: 0.06),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _benefitRow(Icons.all_inclusive, '무제한 AI 일기 변환'),
          const SizedBox(height: 12),
          _benefitRow(Icons.flash_on_rounded, '광고 없이 바로 사용'),
          const SizedBox(height: 12),
          _benefitRow(Icons.auto_awesome, '천사 & 악마 버전 무제한'),
          const SizedBox(height: 12),
          _benefitRow(Icons.speed, '빠른 AI 응답 우선 처리'),
        ],
      ),
    );
  }

  Widget _benefitRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF7C5CFC), Color(0xFFFF8FAB)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF2D2D3A)),
          ),
        ),
        const Icon(Icons.check_circle, color: Color(0xFF7C5CFC), size: 22),
      ],
    );
  }

  // ── 가격 플랜 카드 ──
  Widget _buildPlanCard({
    required String title,
    required String price,
    required String period,
    required String description,
    required String productId,
    required bool isPopular,
    required List<Color> gradient,
  }) {
    final isHighlighted = isPopular;

    return GestureDetector(
      onTap: () => _handlePurchase(productId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isHighlighted
              ? LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          color: isHighlighted ? null : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: isHighlighted
              ? null
              : Border.all(color: const Color(0xFF7C5CFC).withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: isHighlighted
                  ? const Color(0xFF7C5CFC).withValues(alpha: 0.25)
                  : const Color(0xFF7C5CFC).withValues(alpha: 0.06),
              blurRadius: isHighlighted ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                        style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: isHighlighted ? Colors.white : const Color(0xFF2D2D3A),
                        ),
                      ),
                      if (isPopular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('BEST',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isHighlighted ? Colors.white.withValues(alpha: 0.8) : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(price,
                      style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800,
                        color: isHighlighted ? Colors.white : const Color(0xFF5A3ED9),
                      ),
                    ),
                    if (period.isNotEmpty)
                      Text(period,
                        style: TextStyle(
                          fontSize: 13,
                          color: isHighlighted ? Colors.white.withValues(alpha: 0.7) : Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 구매 처리 ──
  Future<void> _handlePurchase(String productId) async {
    final product = _purchaseService.getProduct(productId);

    if (product != null) {
      await _purchaseService.buyProduct(product);
    } else {
      // 스토어에 상품이 없으면 (개발 중) 안내
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('현재 준비 중입니다. 곧 이용 가능합니다! 🚀'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: const Color(0xFF7C5CFC),
          ),
        );
      }
    }
  }

  // ── 복원 처리 ──
  Future<void> _handleRestore() async {
    setState(() => _restoring = true);
    await _purchaseService.restorePurchases();
    if (mounted) {
      setState(() => _restoring = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _purchaseService.isPremium
                ? '✅ 프리미엄이 복원되었습니다!'
                : '복원할 구매 내역이 없습니다.',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: _purchaseService.isPremium
              ? const Color(0xFF7C5CFC)
              : Colors.grey.shade600,
        ),
      );
      if (_purchaseService.isPremium) {
        Navigator.pop(context, true);
      }
    }
  }
}
