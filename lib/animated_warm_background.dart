import 'dart:math';
import 'package:flutter/material.dart';

/// 감성적이고 따뜻한 움직이는 원 패턴 배경
class AnimatedWarmBackground extends StatefulWidget {
  final Color? mainColor;
  const AnimatedWarmBackground({super.key, this.mainColor});

  @override
  State<AnimatedWarmBackground> createState() => _AnimatedWarmBackgroundState();
}

class _AnimatedWarmBackgroundState extends State<AnimatedWarmBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Blob> _blobs = [];
  final int _blobCount = 7;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 16))
      ..repeat();
    final rand = Random();
    for (int i = 0; i < _blobCount; i++) {
      Color baseColor = _warmColors[i % _warmColors.length];
      if (i == 0 && widget.mainColor != null) {
        baseColor = widget.mainColor!;
      }
      _blobs.add(_Blob(
        color: baseColor.withOpacity(0.22 + rand.nextDouble() * 0.18),
        size: 110.0 + rand.nextDouble() * 70,
        dx: rand.nextDouble(),
        dy: rand.nextDouble(),
        speed: 0.4 + rand.nextDouble() * 0.7,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final size = MediaQuery.of(context).size;
        return CustomPaint(
          size: size,
          painter: _WarmBackgroundPainter(_blobs, _controller.value),
        );
      },
    );
  }
}

class _Blob {
  final Color color;
  final double size;
  final double dx, dy, speed;
  _Blob({required this.color, required this.size, required this.dx, required this.dy, required this.speed});
}

const List<Color> _warmColors = [
  Color(0xFFFFB6A6), // peach
  Color(0xFFFFE0E6), // soft pink
  Color(0xFFFFF2E0), // warm cream
  Color(0xFFFFD6C0), // light apricot
  Color(0xFFFFC1A6), // orange-peach
  Color(0xFFFFB6B9), // pink
  Color(0xFFFFE6C0), // yellow-peach
];

class _WarmBackgroundPainter extends CustomPainter {
  final List<_Blob> blobs;
  final double t;
  _WarmBackgroundPainter(this.blobs, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < blobs.length; i++) {
      final b = blobs[i];
      final angle = t * 2 * pi * b.speed + i;
      final x = (b.dx * 0.6 + 0.2) * size.width + cos(angle) * 40;
      final y = (b.dy * 0.5 + 0.2) * size.height + sin(angle) * 40;
      final paint = Paint()..color = b.color;
      canvas.drawCircle(Offset(x, y), b.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WarmBackgroundPainter oldDelegate) => true;
}
