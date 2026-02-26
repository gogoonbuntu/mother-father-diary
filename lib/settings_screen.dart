import 'package:flutter/material.dart';
import 'package:diary_app/generated/app_localizations.dart';
import 'package:diary_app/theme_selector.dart';
import 'package:diary_app/google_sign_in_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

class SettingsScreen extends StatefulWidget {
  final Color currentColor;
  final List<Color> colorOptions;
  final String currentFont;
  final List<String> fontOptions;
  final ValueChanged<Color> onColorSelected;
  final ValueChanged<String> onFontSelected;

  const SettingsScreen({
    Key? key,
    required this.currentColor,
    required this.colorOptions,
    required this.currentFont,
    required this.fontOptions,
    required this.onColorSelected,
    required this.onFontSelected,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loggingOut = false;
  late Color _currentColor;
  late String _currentFont;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.currentColor;
    _currentFont = widget.currentFont;
  }

  /// 이메일 보내기 (버그리포트 / 개선제안)
  Future<void> _sendEmail({required bool isBugReport}) async {
    final subject = isBugReport
        ? '[부모일기] 버그 리포트'
        : '[부모일기] 개선 제안';
    final body = isBugReport
        ? '안녕하세요,\n\n[버그 설명]\n\n\n[재현 방법]\n1. \n2. \n3. \n\n[기기 정보]\n- OS: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}\n- 앱 버전: 1.0.0\n'
        : '안녕하세요,\n\n[개선 제안 내용]\n\n\n[기대 효과]\n\n\n감사합니다!\n';

    final uri = Uri(
      scheme: 'mailto',
      path: 'tmddud333@naver.com',
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이메일 앱을 열 수 없습니다. tmddud333@naver.com 으로 직접 보내주세요.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings)),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ThemeSelector(
              currentColor: _currentColor,
              colorOptions: widget.colorOptions,
              onColorSelected: (color) {
                setState(() {
                  _currentColor = color;
                });
                widget.onColorSelected(color);
                Feedback.forTap(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.colorSelected),
                    duration: const Duration(milliseconds: 700),
                  ),
                );
              },
              currentFont: _currentFont,
              fontOptions: widget.fontOptions,
              onFontSelected: (font) {
                setState(() {
                  _currentFont = font;
                });
                widget.onFontSelected(font);
                Feedback.forTap(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.fontSelected),
                    duration: const Duration(milliseconds: 700),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // 📬 버그리포트 & 개선제안
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.mail_outline, size: 20, color: Colors.black87),
                      SizedBox(width: 8),
                      Text(
                        '의견 보내기',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '버그나 개선 아이디어를 알려주세요!',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _sendEmail(isBugReport: true),
                          icon: const Icon(Icons.bug_report, size: 18),
                          label: const Text('버그 리포트', style: TextStyle(fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade600,
                            side: BorderSide(color: Colors.red.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _sendEmail(isBugReport: false),
                          icon: const Icon(Icons.lightbulb_outline, size: 18),
                          label: const Text('개선 제안', style: TextStyle(fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue.shade600,
                            side: BorderSide(color: Colors.blue.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: _loggingOut
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(AppLocalizations.of(context)!.logout),
                onPressed: _loggingOut
                    ? null
                    : () async {
                        Feedback.forTap(context);
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(AppLocalizations.of(context)!.logout),
                            content: Text(AppLocalizations.of(context)!.logoutConfirm),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: Text(MaterialLocalizations.of(context).okButtonLabel),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          setState(() => _loggingOut = true);
                          await GoogleSignInService.signOut();
                          if (!mounted) return;
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.redAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

