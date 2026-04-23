import 'package:flutter/material.dart';
import 'package:diary_app/generated/app_localizations.dart';
import 'package:diary_app/theme_selector.dart';
import 'package:diary_app/google_sign_in_service.dart';
import 'package:diary_app/privacy_info_screen.dart';
import 'package:diary_app/services/notification_service.dart';
import 'package:diary_app/services/account_service.dart';
import 'package:diary_app/main.dart' show globalLocaleNotifier;
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _deletingAccount = false;
  late Color _currentColor;
  late String _currentFont;
  bool _notificationEnabled = true;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.currentColor;
    _currentFont = widget.currentFont;
    _loadNotificationSetting();
  }

  Future<void> _loadNotificationSetting() async {
    final enabled = await NotificationService().isEnabled();
    if (mounted) {
      setState(() => _notificationEnabled = enabled);
    }
  }

  /// 이메일 보내기 (버그리포트 / 개선제안)
  Future<void> _sendEmail({required bool isBugReport}) async {
    final l10n = AppLocalizations.of(context)!;
    final subject = isBugReport
        ? '[${l10n.shareCardAppName}] ${l10n.bugReport}'
        : '[${l10n.shareCardAppName}] ${l10n.improvementSuggestion}';
    final body = isBugReport
        ? l10n.bugReportTemplate('${Platform.operatingSystem} ${Platform.operatingSystemVersion}')
        : l10n.improvementTemplate;

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
          SnackBar(content: Text(l10n.emailFallback)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings)),
      body: SingleChildScrollView(
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

            // 🌐 언어 선택
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF7C5CFC).withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language, size: 20, color: Color(0xFF7C5CFC)),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.selectTheme.replaceAll(AppLocalizations.of(context)!.theme, '🌐'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildLanguageChip(context, '🇰🇷', '한국어', 'ko'),
                      const SizedBox(width: 8),
                      _buildLanguageChip(context, '🇺🇸', 'English', 'en'),
                      const SizedBox(width: 8),
                      _buildLanguageChip(context, '🇯🇵', '日本語', 'ja'),
                      const SizedBox(width: 8),
                      _buildLanguageChip(context, '🇫🇷', 'Français', 'fr'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

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
                  Row(
                    children: [
                      const Icon(Icons.mail_outline, size: 20, color: Colors.black87),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.sendFeedback,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.feedbackSubtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _sendEmail(isBugReport: true),
                          icon: const Icon(Icons.bug_report, size: 18),
                          label: Text(AppLocalizations.of(context)!.bugReport, style: const TextStyle(fontSize: 13)),
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
                          label: Text(AppLocalizations.of(context)!.improvementSuggestion, style: const TextStyle(fontSize: 13)),
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

            const SizedBox(height: 16),

            // 🔔 알림 설정
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3EEFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF7C5CFC).withOpacity(0.2)),
              ),
              child: SwitchListTile(
                value: _notificationEnabled,
                onChanged: (value) async {
                  setState(() => _notificationEnabled = value);
                  await NotificationService().setEnabled(value);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(value ? '🔔 매일 저녁 9시에 알려드릴게요!' : '🔕 일기 알림을 껐어요.'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: const Color(0xFF7C5CFC),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                secondary: Icon(
                  _notificationEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                  color: const Color(0xFF7C5CFC),
                ),
                title: Text(AppLocalizations.of(context)!.diaryNotification, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  AppLocalizations.of(context)!.notificationSubtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                activeColor: const Color(0xFF7C5CFC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (_notificationEnabled)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await NotificationService().showTestNotification();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('🧪 테스트 알림을 보냈어요! 알림 센터를 확인하세요.'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: const Color(0xFF7C5CFC),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.science_rounded, size: 18),
                    label: Text(AppLocalizations.of(context)!.testNotification, style: const TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7C5CFC),
                      side: const BorderSide(color: Color(0xFF7C5CFC)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // 🔒 데이터 보호
            Container(
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: ListTile(
                leading: Icon(Icons.shield_rounded, color: Colors.green.shade600),
                title: Text(AppLocalizations.of(context)!.dataProtection, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(AppLocalizations.of(context)!.e2eEncryption, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrivacyInfoScreen()),
                  );
                },
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

            const SizedBox(height: 16),

            // 🗑️ 계정 삭제
            Container(
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: ListTile(
                leading: Icon(Icons.delete_forever_rounded, color: Colors.red.shade600),
                title: Text(
                  AppLocalizations.of(context)!.deleteAccount,
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red.shade700),
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!.deleteAccountSubtitle,
                  style: TextStyle(fontSize: 12, color: Colors.red.shade400),
                ),
                trailing: _deletingAccount
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.chevron_right, color: Colors.red.shade400),
                onTap: _deletingAccount ? null : _handleDeleteAccount,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 계정 삭제 핸들러 — 2단계 확인 다이얼로그
  Future<void> _handleDeleteAccount() async {
    final l10n = AppLocalizations.of(context)!;

    // 1단계: 경고
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade600, size: 28),
            const SizedBox(width: 8),
            Text(l10n.deleteAccount),
          ],
        ),
        content: Text(l10n.deleteAccountWarning1),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.deleteAccountContinue),
          ),
        ],
      ),
    );

    if (firstConfirm != true || !mounted) return;

    // 2단계: 최종 확인
    final finalConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('⚠️ ${l10n.deleteAccountFinalTitle}'),
        content: Text(l10n.deleteAccountWarning2),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.deleteAccountConfirm),
          ),
        ],
      ),
    );

    if (finalConfirm != true || !mounted) return;

    // 삭제 실행
    setState(() => _deletingAccount = true);
    try {
      await AccountService.deleteAccount();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      // requires-recent-login 에러 시 재인증
      if (e.toString().contains('requires-recent-login')) {
        final reauthed = await AccountService.reauthenticateWithGoogle();
        if (reauthed && mounted) {
          try {
            await AccountService.deleteAccount();
            if (!mounted) return;
            Navigator.of(context).popUntil((route) => route.isFirst);
          } catch (e2) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.deleteAccountError)),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.deleteAccountError)),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.deleteAccountError)),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingAccount = false);
    }
  }

  Widget _buildLanguageChip(BuildContext context, String flag, String label, String langCode) {
    final currentCode = globalLocaleNotifier.value?.languageCode ??
        Localizations.localeOf(context).languageCode;
    final isSelected = currentCode == langCode;

    return Expanded(
      child: GestureDetector(
        onTap: () async {
          final newLocale = Locale(langCode);
          globalLocaleNotifier.value = newLocale;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('app_locale', langCode);
          if (mounted) {
            setState(() {});
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF7C5CFC) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF7C5CFC) : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: const Color(0xFF7C5CFC).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                : [],
          ),
          child: Column(
            children: [
              Text(flag, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
