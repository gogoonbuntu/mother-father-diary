import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'animated_warm_background.dart';
import 'theme_selector.dart';
import 'package:diary_app/google_sign_in_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;

  Color _bgColor = const Color(0xFFFFE0E6);
  String _fontFamily = 'NanumPenScript';

  static const List<Color> _colorOptions = [
    Color(0xFFFFE0E6), // soft pink
    Color(0xFFFFF2E0), // warm cream
    Color(0xFFFFB6A6), // peach
    Color(0xFFFFD6C0), // light apricot
    Color(0xFFFFB6B9), // pink
    Color(0xFFFFE6C0), // yellow-peach
    Color(0xFFFAF4E6), // ivory
    Color(0xFFF9E7E7), // light rose
  ];

  static const List<String> _fontOptions = [
    'NanumPenScript',
    'NanumBrushScript',
    'DancingScript',
    'Jua',
    'GowunDodum',
    'Sunflower',
    'Roboto',
    'NotoSerifKR',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedWarmBackground(
            mainColor: _bgColor,
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Card(
                    elevation: 12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                    color: Colors.white.withOpacity(0.93),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 44),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: _bgColor,
                            child: Icon(Icons.favorite_rounded, size: 52, color: Color(0xFFFF8C7A)),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            AppLocalizations.of(context)!.appTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF8C7A),
                              letterSpacing: 0.5,
                              fontFamily: _fontFamily,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.loginSubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 17, color: Color(0xFF9E616A), fontFamily: _fontFamily),
                          ),
                          const SizedBox(height: 34),
                          _loading
                              ? const CircularProgressIndicator(color: Color(0xFFFF8C7A))
                              : SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: Image.asset(
                                      'assets/google_logo.png',
                                      height: 24,
                                      width: 24,
                                      errorBuilder: (c, e, s) => const Icon(Icons.login),
                                    ),
                                    label: Text(
                                      AppLocalizations.of(context)!.googleSignIn,
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF9E616A), fontFamily: _fontFamily),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _bgColor,
                                      foregroundColor: const Color(0xFF9E616A),
                                      elevation: 2,
                                      side: const BorderSide(color: Color(0xFFFFB6A6), width: 1.2),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    onPressed: () async {
                                      setState(() => _loading = true);
                                      try {
                                        await GoogleSignInService.signInWithGoogle();
                                      } catch (e) {
                                        String msg;
                                        if (e.toString().contains('network_offline')) {
                                          msg = '네트워크 연결을 확인해주세요.';
                                        } else {
                                          msg = '로그인 중 오류가 발생했습니다. 다시 시도해주세요.';
                                        }
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(msg)),
                                          );
                                        }
                                      } finally {
                                        if (mounted) setState(() => _loading = false);
                                      }
                                    },
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ThemeSelector(
                    currentColor: _bgColor,
                    colorOptions: _colorOptions,
                    onColorSelected: (color) => setState(() => _bgColor = color),
                    currentFont: _fontFamily,
                    fontOptions: _fontOptions,
                    onFontSelected: (font) => setState(() => _fontFamily = font),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
