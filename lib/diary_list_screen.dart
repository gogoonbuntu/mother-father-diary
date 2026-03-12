import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:diary_app/generated/app_localizations.dart';
import 'package:diary_app/models/diary_entry.dart';
import 'package:diary_app/services/diary_service.dart';
import 'package:diary_app/diary_entry_screen.dart' show DiaryEntryScreen;

class DiaryListScreen extends StatefulWidget {
  final Color? bgColor;
  final String? fontFamily;
  const DiaryListScreen({super.key, this.bgColor, this.fontFamily});

  @override
  State<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends State<DiaryListScreen> {
  List<DiaryEntry> _diaryEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiaryEntries();
  }

  Future<void> _loadDiaryEntries() async {
    setState(() { _isLoading = true; });
    try {
      final entries = await DiaryService().getDiaryEntries();
      if (mounted) {
        setState(() {
          _diaryEntries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading diary entries: \$e');
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  void _openDiaryEntry({DiaryEntry? entry}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: DiaryEntryScreen(
            diaryEntry: entry,
            bgColor: widget.bgColor,
            fontFamily: widget.fontFamily,
            scrollController: scrollController,
          ),
        ),
      ),
    ).then((_) => _loadDiaryEntries());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 일기 목록
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDiaryEntries,
                child: _diaryEntries.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                          top: 12, left: 16, right: 16, bottom: 100,
                        ),
                        itemCount: _diaryEntries.length,
                        itemBuilder: (context, index) {
                          final entry = _diaryEntries[index];
                          return _buildDiaryCard(entry);
                        },
                      ),
              ),

        // FAB: 새 일기 쓰기
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: SafeArea(
            child: GestureDetector(
              onTap: () => _openDiaryEntry(),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C5CFC), Color(0xFF9B7DFF)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C5CFC).withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 10),
                    Text(
                      '✏️ 새 일기 쓰기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        const Center(
          child: Column(
            children: [
              Text('📝', style: TextStyle(fontSize: 64)),
              SizedBox(height: 16),
              Text(
                '아직 일기가 없어요',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5A3ED9),
                ),
              ),
              SizedBox(height: 8),
              Text(
                '아래 버튼을 눌러 첫 일기를 작성해보세요!',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiaryCard(DiaryEntry entry) {
    final dateStr = DateFormat('yyyy.MM.dd (E)', 'ko').format(entry.date);
    final preview = entry.content.split('\n').take(3).join('\n');
    final hasMood = entry.mood != null && entry.mood!.isNotEmpty;

    return GestureDetector(
      onTap: () => _openDiaryEntry(entry: entry),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF7C5CFC).withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C5CFC).withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF5A3ED9),
                  ),
                ),
                if (hasMood) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C5CFC).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      entry.mood!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF7C5CFC)),
                    ),
                  ),
                ],
                const Spacer(),
                // 삭제 버튼
                GestureDetector(
                  onTap: () async {
                    bool confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('삭제 확인'),
                        content: const Text('이 일기를 삭제하시겠습니까?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
                        ],
                      ),
                    );
                    if (confirm) {
                      await DiaryService().deleteDiaryEntry(entry.id);
                      _loadDiaryEntries();
                    }
                  },
                  child: Icon(Icons.delete_outline_rounded, size: 20, color: Colors.grey.shade400),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              preview,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
            ),
            if (entry.positiveVersion != null || entry.devilVersion != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (entry.positiveVersion != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C5CFC).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('😇', style: TextStyle(fontSize: 12)),
                    ),
                  if (entry.positiveVersion != null && entry.devilVersion != null)
                    const SizedBox(width: 4),
                  if (entry.devilVersion != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8577E).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('😈', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
