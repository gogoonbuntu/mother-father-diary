import 'package:flutter/material.dart';
import 'package:diary_app/generated/app_localizations.dart';
import 'package:diary_app/main.dart' show kSupportedFonts;
import 'animated_warm_background.dart';
import 'theme_selector.dart';
import 'package:diary_app/google_sign_in_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;

  Color _bgColor = const Color(0xFFFFE0E6);
  String _fontFamily = 'Nanum Gothic';

  static const List<Color> _colorOptions = [
    Color(0xFFFFE0E6), // 핑크
    Color(0xFFFFF2E0), // 크림
    Color(0xFFE0F5E8), // 민트
    Color(0xFFE8E0F5), // 라벤더
    Color(0xFFE0ECF5), // 스카이 블루
    Color(0xFFFAF4E6), // 아이보리
  ];

  static const List<String> _fontOptions = kSupportedFonts;

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
                                        final userCredential = await GoogleSignInService.signInWithGoogle();
                                        // 로그인 성공 시 오류 메시지 표시하지 않음
                                        if (userCredential == null) {
                                          // 사용자가 로그인을 취소한 경우
                                          print('로그인이 취소되었습니다.');
                                        }
                                      } catch (e) {
                                        print('로그인 오류 상세: $e');
                                        // Firebase Auth가 이미 성공한 경우 에러 표시하지 않음
                                        final isAlreadySignedIn = FirebaseAuth.instance.currentUser != null;
                                        if (!isAlreadySignedIn && mounted) {
                                          String msg;
                                          if (e.toString().contains('network_offline')) {
                                            msg = AppLocalizations.of(context)!.networkError;
                                          } else {
                                            msg = AppLocalizations.of(context)!.loginError;
                                          }
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
