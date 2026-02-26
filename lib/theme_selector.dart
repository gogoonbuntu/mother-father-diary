import 'package:flutter/material.dart';
import 'package:diary_app/generated/app_localizations.dart';

class ThemeSelector extends StatelessWidget {
  final Color currentColor;
  final List<Color> colorOptions;
  final ValueChanged<Color> onColorSelected;
  final String currentFont;
  final List<String> fontOptions;
  final ValueChanged<String> onFontSelected;

  const ThemeSelector({
    super.key,
    required this.currentColor,
    required this.colorOptions,
    required this.onColorSelected,
    required this.currentFont,
    required this.fontOptions,
    required this.onFontSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.selectTheme, style: const TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 10,
          children: colorOptions.map((color) => InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Feedback.forTap(context);
              onColorSelected(color);
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(
                      color: color == currentColor ? Colors.black : Colors.grey.shade400,
                      width: color == currentColor ? 2.5 : 1.0,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                if (color == currentColor)
                  const Icon(Icons.check, color: Colors.black, size: 18),
              ],
            ),
          )).toList(),
        ),
        const SizedBox(height: 16),
        Text(AppLocalizations.of(context)!.selectFont, style: const TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 10,
          children: fontOptions.map((font) => InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Feedback.forTap(context);
              onFontSelected(font);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: font == currentFont ? Colors.blue.shade50 : Colors.white,
                border: Border.all(
                  color: font == currentFont ? Colors.blue : Colors.grey.shade400,
                  width: font == currentFont ? 2.0 : 1.0,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    font,
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 17,
                      color: Colors.black87,
                      fontWeight: font == currentFont ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (font == currentFont)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.check, size: 16, color: Colors.blue),
                    ),
                ],
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }
}
