import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:diary_app/theme_selector.dart';
import 'package:diary_app/google_sign_in_service.dart';

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
                Feedback.forTap(context); // Haptic feedback
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
                Feedback.forTap(context); // Haptic feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.fontSelected),
                    duration: const Duration(milliseconds: 700),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: _loggingOut
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(AppLocalizations.of(context)!.logout),
                onPressed: _loggingOut
                    ? null
                    : () async {
                        Feedback.forTap(context); // Haptic feedback
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
