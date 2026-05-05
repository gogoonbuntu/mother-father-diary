import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:diary_app/generated/app_localizations.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class ShareService {
  /// 기분 이모지 매핑
  static String _moodEmoji(String mood) {
    switch (mood) {
      case 'Happy':
        return '😊';
      case 'Sad':
        return '😢';
      case 'Neutral':
        return '😐';
      default:
        return '📝';
    }
  }

  /// 날짜 포맷팅
  static String _formatDate(DateTime date) {
    return DateFormat('yyyy년 MM월 dd일').format(date);
  }

  /// 이미지 카드 생성 후 공유
  static Future<void> shareAsImage(
    BuildContext context, {
    required DateTime date,
    required String mood,
    String? originalContent,
    String? angelVersion,
    String? devilVersion,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    // 카드 위젯 생성
    final cardWidget = _buildShareCard(
      date: date,
      mood: mood,
      originalContent: originalContent,
      angelVersion: angelVersion,
      devilVersion: devilVersion,
      brandingText: l10n.shareCardBranding,
    );

    // 위젯을 이미지로 렌더링
    final imageBytes = await _widgetToImage(cardWidget);
    if (imageBytes == null) {
      // fallback: 텍스트 공유
      await Share.share(_buildFallbackText(date, mood, originalContent, angelVersion, devilVersion));
      return;
    }

    // 임시 파일로 저장
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/diary_share_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(imageBytes);

    // 이미지 + 텍스트 공유
    await Share.shareXFiles(
      [XFile(file.path)],
      text: '✨ 럭키비키 일기장으로 오늘 하루를 기록해보세요!\n📲 https://play.google.com/store/apps/details?id=com.motherfatherdiary.app',
    );
  }

  /// 카드 위젯 → PNG bytes
  static Future<Uint8List?> _widgetToImage(Widget widget) async {
    try {
      final repaintBoundary = RenderRepaintBoundary();
      
      final renderView = RenderView(
        view: ui.PlatformDispatcher.instance.views.first,
        child: RenderPositionedBox(
          alignment: Alignment.center,
          child: repaintBoundary,
        ),
        configuration: ViewConfiguration(
          logicalConstraints: BoxConstraints.tight(const Size(420, 600)),
          devicePixelRatio: 3.0,
        ),
      );

      final pipelineOwner = PipelineOwner();
      pipelineOwner.rootNode = renderView;
      renderView.prepareInitialFrame();

      final buildOwner = BuildOwner(focusManager: FocusManager());
      final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
        container: repaintBoundary,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: ui.TextDirection.ltr,
            child: Material(
              color: Colors.transparent,
              child: widget,
            ),
          ),
        ),
      ).attachToRenderTree(buildOwner);

      buildOwner.buildScope(rootElement);
      pipelineOwner.flushLayout();
      pipelineOwner.flushCompositingBits();
      pipelineOwner.flushPaint();

      final image = await repaintBoundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('[공유] 이미지 생성 실패: $e');
      return null;
    }
  }

  /// 공유 카드 위젯 (420x600 크기)
  static Widget _buildShareCard({
    required DateTime date,
    required String mood,
    String? originalContent,
    String? angelVersion,
    String? devilVersion,
    required String brandingText,
  }) {
    final isAngel = angelVersion != null && angelVersion.isNotEmpty;
    final isDevil = devilVersion != null && devilVersion.isNotEmpty;

    final gradientColors = isDevil && !isAngel
        ? [const Color(0xFFFFE0E8), const Color(0xFFFFF0F3)]
        : [const Color(0xFFF0EBFF), const Color(0xFFF8F5FF)];

    final accentColor = isDevil && !isAngel
        ? const Color(0xFFE8577E)
        : const Color(0xFF7C5CFC);

    // 표시할 콘텐츠 결정
    String displayContent = '';
    String displayLabel = '';
    if (isAngel) {
      displayContent = angelVersion;
      displayLabel = '😇 천사의 위로';
    } else if (isDevil) {
      displayContent = devilVersion;
      displayLabel = '😈 악마의 공감';
    } else if (originalContent != null) {
      displayContent = originalContent;
      displayLabel = '📝 오늘의 일기';
    }

    // 긴 텍스트 자르기
    if (displayContent.length > 200) {
      displayContent = '${displayContent.substring(0, 200)}...';
    }

    return Container(
      width: 420,
      height: 600,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더: 앱 이름
            Row(
              children: [
                Text(
                  '✨',
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 6),
                Text(
                  '럭키비키 일기장',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // 날짜 + 기분
            Text(
              '${_moodEmoji(mood)}  ${_formatDate(date)}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            // 구분선
            Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor.withValues(alpha: 0.6), accentColor.withValues(alpha: 0.0)],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 16),
            // 라벨
            if (displayLabel.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  displayLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            const SizedBox(height: 14),
            // 콘텐츠
            Expanded(
              child: Text(
                displayContent,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.7,
                  color: const Color(0xFF2D2D3A),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.fade,
              ),
            ),
            const SizedBox(height: 16),
            // 하단: 설치 링크
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accentColor.withValues(alpha: 0.15)),
              ),
              child: Column(
                children: [
                  Text(
                    brandingText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'play.google.com/store/apps/details?id=com.motherfatherdiary.app',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 폴백용 텍스트 생성
  static String _buildFallbackText(
    DateTime date,
    String mood,
    String? originalContent,
    String? angelVersion,
    String? devilVersion,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('${_moodEmoji(mood)} ${_formatDate(date)}의 일기');
    buffer.writeln('');

    if (originalContent != null && originalContent.isNotEmpty) {
      buffer.writeln('📝 원본 일기');
      buffer.writeln('─────────────');
      buffer.writeln(originalContent);
      buffer.writeln('');
    }

    if (angelVersion != null && angelVersion.isNotEmpty) {
      buffer.writeln('😇 천사의 위로');
      buffer.writeln('─────────────');
      buffer.writeln(angelVersion);
      buffer.writeln('');
    }

    if (devilVersion != null && devilVersion.isNotEmpty) {
      buffer.writeln('😈 악마의 공감');
      buffer.writeln('─────────────');
      buffer.writeln(devilVersion);
      buffer.writeln('');
    }

    buffer.writeln('✨ 럭키비키 일기장');
    buffer.writeln('📲 https://play.google.com/store/apps/details?id=com.motherfatherdiary.app');
    return buffer.toString().trimRight();
  }
}
