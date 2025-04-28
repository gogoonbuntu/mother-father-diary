import 'package:flutter/material.dart';

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
        const Text('배경색 선택', style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 10,
          children: colorOptions.map((color) => GestureDetector(
            onTap: () => onColorSelected(color),
            child: Container(
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
          )).toList(),
        ),
        const SizedBox(height: 16),
        const Text('폰트 선택', style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 10,
          children: fontOptions.map((font) => GestureDetector(
            onTap: () => onFontSelected(font),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: font == currentFont ? Colors.grey.shade200 : Colors.white,
                border: Border.all(
                  color: font == currentFont ? Colors.black : Colors.grey.shade400,
                  width: font == currentFont ? 2.0 : 1.0,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                font,
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 17,
                  color: Colors.black87,
                  fontWeight: font == currentFont ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }
}
