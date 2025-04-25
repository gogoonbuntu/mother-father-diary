import 'package:flutter/material.dart';
import 'dart:math';

/// 다양한 테마 색상과 파티클 모양을 정의
class ConfettiTheme {
  final List<Color> colors;
  final Path Function(Size) particleShape;
  final String name;

  ConfettiTheme({required this.colors, required this.particleShape, required this.name});
}

// 별 모양
Path starPath(Size size) {
  final path = Path();
  const numberOfPoints = 5;
  final halfWidth = size.width / 2;
  final halfHeight = size.height / 2;
  final radius = size.width / 2;
  double degToRad(double deg) => deg * (pi / 180.0);
  final angle = 360 / numberOfPoints;
  for (int i = 0; i < numberOfPoints; i++) {
    final x = halfWidth + radius * cos(degToRad(angle * i - 90));
    final y = halfHeight + radius * sin(degToRad(angle * i - 90));
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
    final x2 = halfWidth + radius * 0.5 * cos(degToRad(angle * i - 90 + angle / 2));
    final y2 = halfHeight + radius * 0.5 * sin(degToRad(angle * i - 90 + angle / 2));
    path.lineTo(x2, y2);
  }
  path.close();
  return path;
}

// 하트 모양
Path heartPath(Size size) {
  final path = Path();
  final width = size.width;
  final height = size.height;
  path.moveTo(width / 2, height * 0.8);
  path.cubicTo(width * 1.2, height * 0.35, width * 0.8, height * -0.1, width / 2, height * 0.3);
  path.cubicTo(width * 0.2, height * -0.1, width * -0.2, height * 0.35, width / 2, height * 0.8);
  path.close();
  return path;
}

// 꽃잎 모양
Path flowerPath(Size size) {
  final path = Path();
  final center = Offset(size.width / 2, size.height / 2);
  final radius = size.width / 2;
  for (int i = 0; i < 6; i++) {
    final angle = (pi / 3) * i;
    final x = center.dx + radius * cos(angle);
    final y = center.dy + radius * sin(angle);
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }
  path.close();
  return path;
}

final List<ConfettiTheme> confettiThemes = [
  ConfettiTheme(
    name: '봄',
    colors: [Colors.pinkAccent, Colors.yellow, Colors.greenAccent, Colors.white],
    particleShape: flowerPath,
  ),
  ConfettiTheme(
    name: '여름',
    colors: [Colors.blue, Colors.cyan, Colors.yellowAccent, Colors.green],
    particleShape: starPath,
  ),
  ConfettiTheme(
    name: '가을',
    colors: [Colors.orange, Colors.brown, Colors.redAccent, Colors.amber],
    particleShape: heartPath,
  ),
  ConfettiTheme(
    name: '겨울',
    colors: [Colors.white, Colors.lightBlueAccent, Colors.grey, Colors.blueGrey],
    particleShape: starPath,
  ),
  ConfettiTheme(
    name: '무지개',
    colors: [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.indigo, Colors.purple],
    particleShape: starPath,
  ),
];
