import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class OpeningBanner extends StatefulWidget {
  final VoidCallback onFinish;
  const OpeningBanner({required this.onFinish, super.key});

  @override
  State<OpeningBanner> createState() => _OpeningBannerState();
}

class _OpeningBannerState extends State<OpeningBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _adTried = false;

  void _loadAd(String adUnitId) {
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isLoaded = true;
          });
          Future.delayed(const Duration(seconds: 2), widget.onFinish);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!_adTried) {
            setState(() {
              _adTried = true;
            });
            widget.onFinish();
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 실제 광고 단위 ID (테스트 후 사용)
    // final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    // final adUnitId = isIOS
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final adUnitId = isIOS
        ? 'ca-app-pub-3343461027648901/9169459723' // 실제 iOS 광고 단위 ID
        : 'ca-app-pub-3343461027648901/9978919028'; // 실제 Android 광고 단위 ID
    if (_bannerAd == null && !_adTried) {
      _loadAd(adUnitId);
    }
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Diary App',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            if (_isLoaded && _bannerAd != null)
              SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              )
            else
              const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
