import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:diary_app/models/diary_entry.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class DiaryService {
  static final DiaryService _instance = DiaryService._internal();
  
  // 로컬 저장소 관련 변수
  List<DiaryEntry> _localDiaryEntries = [];
  late File _diaryFile;
  
  // Firebase 관련 변수
  bool _useFirestore = true;
  bool _initialized = false;
  
  // 캐싱 및 최적화 관련 변수
  Map<String, DiaryEntry> _cachedEntries = {}; // 메모리 캐시
  Timer? _saveDebounceTimer; // 저장 디바운스 타이머
  bool _hasPendingChanges = false; // 대기 중인 변경사항 여부
  DateTime _lastSyncTime = DateTime.now(); // 마지막 동기화 시간
  static const Duration _syncInterval = Duration(minutes: 5); // 동기화 간격
  static const Duration _debounceTime = Duration(seconds: 3); // 디바운스 시간

  factory DiaryService() => _instance;

  DiaryService._internal();

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? 'local-user';
  
  // Firebase Realtime Database 참조 - 아시아 지역 URL 사용
  DatabaseReference get _databaseRef => FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://diary-becbb-default-rtdb.asia-southeast1.firebasedatabase.app'
  ).ref();
  
  // 사용자별 일기 경로
  DatabaseReference get _userDiariesRef => _databaseRef.child('users/$_userId/diaries');

  Future<void> init() async {
    if (_initialized) return;
    
    // 로컬 저장소 초기화
    final directory = await getApplicationDocumentsDirectory();
    _diaryFile = File('${directory.path}/diary_entries.json');
    await _loadLocalDiaryEntries();
    
    // Firebase Realtime Database 사용 가능 여부 확인
    try {
      await _databaseRef.child('test').get();
      _useFirestore = true;
      debugPrint('Firebase Realtime Database is available and will be used');
      
      // 초기 로드 후 캐싱
      await _loadAndCacheRemoteEntries();
      
      // 주기적 동기화 타이머 설정
      _setupPeriodicSync();
    } catch (e) {
      _useFirestore = false;
      debugPrint('Firebase error, falling back to local storage: $e');
    }
    
    _initialized = true;
  }
  
  // 주기적 동기화 타이머 설정
  void _setupPeriodicSync() {
    Timer.periodic(_syncInterval, (_) {
      if (_hasPendingChanges) {
        _syncToDatabase();
      }
    });
  }
  
  // 원격 데이터를 가져와서 캐싱
  Future<void> _loadAndCacheRemoteEntries() async {
    try {
      final snapshot = await _userDiariesRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          data.forEach((key, value) {
            if (value is Map) {
              final Map<String, dynamic> entryMap = {};
              value.forEach((k, v) => entryMap[k.toString()] = v);
              final entry = DiaryEntry.fromJson(entryMap);
              _cachedEntries[entry.id] = entry;
            }
          });
          debugPrint('Cached ${_cachedEntries.length} entries from remote database');
        }
      }
    } catch (e) {
      debugPrint('Error loading remote entries: $e');
    }
  }

  // 로컬 저장소 관련 메서드
  Future<void> _loadLocalDiaryEntries() async {
    try {
      if (await _diaryFile.exists()) {
        final contents = await _diaryFile.readAsString();
        final jsonList = jsonDecode(contents);
        _localDiaryEntries = jsonList.map<DiaryEntry>((json) => DiaryEntry.fromJson(json)).toList();
        
        // 로컬 데이터도 캐싱
        for (var entry in _localDiaryEntries) {
          _cachedEntries[entry.id] = entry;
        }
      }
    } catch (e) {
      debugPrint('Error loading local diary entries: $e');
      _localDiaryEntries = [];
    }
  }

  Future<void> _saveLocalDiaryEntries() async {
    try {
      // 캐시에서 로컬 리스트 업데이트
      _localDiaryEntries = _cachedEntries.values.toList();
      
      final jsonList = _localDiaryEntries.map((entry) => entry.toJson()).toList();
      await _diaryFile.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving local diary entries: $e');
    }
  }
  
  // 디바운스를 적용한 데이터베이스 동기화
  void _scheduleDatabaseSync() {
    _hasPendingChanges = true;
    
    // 기존 타이머 취소 후 새로 설정
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(_debounceTime, () {
      _syncToDatabase();
    });
  }
  
  // 데이터베이스와 동기화
  Future<void> _syncToDatabase() async {
    if (!_useFirestore || !_hasPendingChanges) return;
    
    try {
      // 배치 업데이트 사용
      final updates = <String, dynamic>{};
      _cachedEntries.forEach((id, entry) {
        updates[id] = entry.toJson();
      });
      
      await _userDiariesRef.update(updates);
      _lastSyncTime = DateTime.now();
      _hasPendingChanges = false;
      debugPrint('Synced ${updates.length} entries to database');
    } catch (e) {
      debugPrint('Error syncing to database: $e');
    }
  }

  // 하이브리드 CRUD 메서드
  Future<void> addDiaryEntry(DiaryEntry entry) async {
    await init();
    final now = DateTime.now();
    final entryWithMetadata = {
      ...entry.toJson(),
      'userId': _userId,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };
    
    // 캐시에 저장
    final diaryEntry = DiaryEntry.fromJson(entryWithMetadata);
    _cachedEntries[entry.id] = diaryEntry;
    
    // 로컬 저장소 업데이트
    await _saveLocalDiaryEntries();
    
    if (_useFirestore) {
      // 디바운스를 적용하여 데이터베이스 업데이트 일정 잠시 지연
      _scheduleDatabaseSync();
    }
  }

  Future<List<DiaryEntry>> getDiaryEntries() async {
    await init();
    
    // 캐시에서 데이터 가져오기 (원격 데이터는 이미 초기화 시 캐싱됨)
    final entries = _cachedEntries.values.toList();
    
    // 마지막 동기화 이후 시간이 오래 지났다면 새로 로드
    final timeSinceLastSync = DateTime.now().difference(_lastSyncTime);
    if (_useFirestore && timeSinceLastSync > const Duration(minutes: 15)) {
      try {
        await _loadAndCacheRemoteEntries();
        _lastSyncTime = DateTime.now();
        return _cachedEntries.values.toList()
          ..sort((a, b) => b.date.compareTo(a.date));
      } catch (e) {
        debugPrint('Firebase get error, using cached data: $e');
      }
    }
    
    // 날짜별로 정렬 (최신순)
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  Future<DiaryEntry?> getDiaryEntryForDate(DateTime date) async {
    await init();
    
    // 캐시에서 찾기
    try {
      return _cachedEntries.values.firstWhere(
        (entry) => isSameDate(entry.date, date),
      );
    } catch (e) {
      // 캐시에 없을 경우 null 반환
      return null;
    }
  }

  Future<void> updateDiaryEntry(String id, DiaryEntry entry) async {
    await init();
    final updatedData = {
      ...entry.toJson(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    
    // 캐시 업데이트
    _cachedEntries[id] = DiaryEntry.fromJson(updatedData);
    
    // 로컬 저장소 업데이트
    await _saveLocalDiaryEntries();
    
    if (_useFirestore) {
      // 디바운스를 적용하여 데이터베이스 업데이트 일정 지연
      _scheduleDatabaseSync();
    }
  }

  Future<void> deleteDiaryEntry(String id) async {
    await init();
    
    // 캐시에서 삭제
    _cachedEntries.remove(id);
    
    // 로컬 저장소 업데이트
    await _saveLocalDiaryEntries();
    
    if (_useFirestore) {
      try {
        // 삭제는 즉시 적용 (디바운스 없이)
        await _userDiariesRef.child(id).remove();
      } catch (e) {
        debugPrint('Firebase delete error: $e');
      }
    }
  }
  
  // 앱 종료 시 동기화 작업 수행
  Future<void> syncOnAppClose() async {
    if (_useFirestore && _hasPendingChanges) {
      await _syncToDatabase();
    }
  }

  // For compatibility: fetch all entries and find by date
  bool isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }
}
