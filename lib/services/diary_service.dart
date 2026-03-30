import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:diary_app/models/diary_entry.dart';
import 'package:diary_app/services/encryption_service.dart';
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
  bool _firebaseAvailable = false;
  bool _initialized = false;
  String? _lastUserId; // 유저 변경 감지용

  // 캐싱 및 최적화 관련 변수
  Map<String, DiaryEntry> _cachedEntries = {}; // 메모리 캐시 (복호화된 원문)
  Timer? _saveDebounceTimer; // 저장 디바운스 타이머
  Timer? _periodicSyncTimer; // 주기적 동기화 타이머
  bool _hasPendingChanges = false;
  DateTime _lastSyncTime = DateTime.now();
  static const Duration _syncInterval = Duration(minutes: 5);
  static const Duration _debounceTime = Duration(seconds: 3);

  // 암호화 서비스
  final EncryptionService _encryption = EncryptionService();

  factory DiaryService() => _instance;

  DiaryService._internal();

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? 'local-user';

  // Firebase Realtime Database 참조
  DatabaseReference get _databaseRef => FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://diary-becbb-default-rtdb.asia-southeast1.firebasedatabase.app'
  ).ref();

  // 사용자별 일기 경로
  DatabaseReference get _userDiariesRef => _databaseRef.child('users/$_userId/diaries');

  Future<void> init() async {
    // 유저가 바뀌면 재초기화 필요
    final currentUserId = _userId;
    if (_initialized && _lastUserId == currentUserId) return;

    if (_lastUserId != null && _lastUserId != currentUserId) {
      debugPrint('[DiaryService] 유저 변경 감지: $_lastUserId → $currentUserId, 재초기화');
      _cachedEntries.clear();
      _hasPendingChanges = false;
      _periodicSyncTimer?.cancel();
      _saveDebounceTimer?.cancel();
    }

    _lastUserId = currentUserId;

    // 암호화 서비스 초기화
    _encryption.initialize();

    // 로컬 저장소 초기화
    final directory = await getApplicationDocumentsDirectory();
    _diaryFile = File('${directory.path}/diary_entries_$currentUserId.json');
    await _loadLocalDiaryEntries();

    // Firebase Realtime Database 사용 가능 여부 확인
    _firebaseAvailable = false;
    if (currentUserId != 'local-user') {
      try {
        // 자기 자신의 경로에서 읽기 테스트 (보안 규칙 통과)
        await _userDiariesRef.limitToFirst(1).get();
        _firebaseAvailable = true;
        debugPrint('[DiaryService] ✅ Firebase Realtime Database 연결 성공');

        // 원격 데이터를 로컬과 병합
        await _mergeRemoteEntries();

        // 주기적 동기화 타이머 설정
        _setupPeriodicSync();
      } catch (e) {
        _firebaseAvailable = false;
        debugPrint('[DiaryService] ❌ Firebase 연결 실패, 로컬 모드: $e');
      }
    }

    // 기존 비암호화 데이터 마이그레이션
    await _migrateUnencryptedEntries();

    _initialized = true;
  }

  // 주기적 동기화 타이머 설정
  void _setupPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(_syncInterval, (_) {
      if (_hasPendingChanges) {
        _syncToFirebase();
      }
    });
  }

  // 원격 데이터를 가져와서 로컬과 병합 (핵심: 앱 재설치 후 복원)
  Future<void> _mergeRemoteEntries() async {
    try {
      final snapshot = await _userDiariesRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          int newCount = 0;
          data.forEach((key, value) {
            if (value is Map) {
              final Map<String, dynamic> entryMap = {};
              value.forEach((k, v) => entryMap[k.toString()] = v);
              try {
                final entry = DiaryEntry.fromJson(entryMap);
                final decrypted = _decryptEntry(entry);
                // 로컬에 없는 항목이면 추가 (ID 기반)
                if (!_cachedEntries.containsKey(entry.id)) {
                  _cachedEntries[entry.id] = decrypted;
                  newCount++;
                } else {
                  // 이미 있으면, updatedAt 비교하여 최신 데이터로 교체
                  final localUpdatedAt = entryMap['updatedAt'];
                  final cachedJson = _cachedEntries[entry.id]!.toJson();
                  final cachedUpdatedAt = cachedJson['updatedAt'];
                  if (localUpdatedAt != null && cachedUpdatedAt != null) {
                    if (localUpdatedAt.toString().compareTo(cachedUpdatedAt.toString()) > 0) {
                      _cachedEntries[entry.id] = decrypted;
                    }
                  }
                }
              } catch (e) {
                debugPrint('[DiaryService] 항목 파싱 실패: $e');
              }
            }
          });
          debugPrint('[DiaryService] 원격에서 $newCount개 새 항목 병합, 총 ${_cachedEntries.length}개');
          // 병합 후 로컬 저장
          if (newCount > 0) {
            await _saveLocalDiaryEntries();
          }
        }
      }
    } catch (e) {
      debugPrint('[DiaryService] 원격 데이터 로드 실패: $e');
    }
  }

  // 로컬 저장소 관련 메서드
  Future<void> _loadLocalDiaryEntries() async {
    try {
      if (await _diaryFile.exists()) {
        final contents = await _diaryFile.readAsString();
        final jsonList = jsonDecode(contents);
        _localDiaryEntries = jsonList.map<DiaryEntry>((json) => DiaryEntry.fromJson(json)).toList();

        for (var entry in _localDiaryEntries) {
          _cachedEntries[entry.id] = _decryptEntry(entry);
        }
        debugPrint('[DiaryService] 로컬에서 ${_localDiaryEntries.length}개 항목 로드');
      }
    } catch (e) {
      debugPrint('[DiaryService] 로컬 로드 실패: $e');
      _localDiaryEntries = [];
    }
  }

  Future<void> _saveLocalDiaryEntries() async {
    try {
      _localDiaryEntries = _cachedEntries.values
          .map((entry) => _encryptEntry(entry))
          .toList();

      final jsonList = _localDiaryEntries.map((entry) => entry.toJson()).toList();
      await _diaryFile.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      debugPrint('[DiaryService] 로컬 저장 실패: $e');
    }
  }

  // 디바운스를 적용한 데이터베이스 동기화
  void _scheduleDatabaseSync() {
    _hasPendingChanges = true;

    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(_debounceTime, () {
      _syncToFirebase();
    });
  }

  // Firebase에 동기화 (암호화 후 업로드) — 즉시 실행 가능
  Future<void> _syncToFirebase() async {
    if (!_firebaseAvailable || !_hasPendingChanges) return;

    try {
      final updates = <String, dynamic>{};
      _cachedEntries.forEach((id, entry) {
        updates[id] = _encryptEntry(entry).toJson();
      });

      await _userDiariesRef.update(updates);
      _lastSyncTime = DateTime.now();
      _hasPendingChanges = false;
      debugPrint('[DiaryService] ✅ Firebase에 ${updates.length}개 항목 동기화 완료');
    } catch (e) {
      debugPrint('[DiaryService] ❌ Firebase 동기화 실패: $e');
    }
  }

  // === CRUD 메서드 ===

  Future<void> addDiaryEntry(DiaryEntry entry) async {
    await init();
    final now = DateTime.now();
    final entryWithMetadata = {
      ...entry.toJson(),
      'userId': _userId,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };

    final diaryEntry = DiaryEntry.fromJson(entryWithMetadata);
    _cachedEntries[entry.id] = diaryEntry;

    // 로컬 저장
    await _saveLocalDiaryEntries();

    if (_firebaseAvailable) {
      // 새 항목은 즉시 Firebase에 업로드 (유실 방지)
      try {
        await _userDiariesRef.child(entry.id).set(_encryptEntry(diaryEntry).toJson());
        debugPrint('[DiaryService] ✅ 새 일기 Firebase에 즉시 저장: ${entry.id}');
      } catch (e) {
        debugPrint('[DiaryService] ❌ Firebase 즉시 저장 실패, 디바운스로 재시도: $e');
        _scheduleDatabaseSync();
      }
    }
  }

  Future<List<DiaryEntry>> getDiaryEntries() async {
    await init();

    final entries = _cachedEntries.values.toList();

    // 15분마다 원격 새로고침
    final timeSinceLastSync = DateTime.now().difference(_lastSyncTime);
    if (_firebaseAvailable && timeSinceLastSync > const Duration(minutes: 15)) {
      try {
        await _mergeRemoteEntries();
        _lastSyncTime = DateTime.now();
        return _cachedEntries.values.toList()
          ..sort((a, b) => b.date.compareTo(a.date));
      } catch (e) {
        debugPrint('[DiaryService] 새로고침 실패, 캐시 사용: $e');
      }
    }

    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  Future<DiaryEntry?> getDiaryEntryForDate(DateTime date) async {
    await init();

    try {
      return _cachedEntries.values.firstWhere(
        (entry) => isSameDate(entry.date, date),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> updateDiaryEntry(String id, DiaryEntry entry) async {
    await init();
    final updatedData = {
      ...entry.toJson(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    _cachedEntries[id] = DiaryEntry.fromJson(updatedData);

    // 로컬 저장
    await _saveLocalDiaryEntries();

    if (_firebaseAvailable) {
      // 업데이트도 즉시 Firebase에 저장
      try {
        await _userDiariesRef.child(id).set(
          _encryptEntry(DiaryEntry.fromJson(updatedData)).toJson()
        );
        debugPrint('[DiaryService] ✅ 일기 업데이트 Firebase에 즉시 저장: $id');
      } catch (e) {
        debugPrint('[DiaryService] ❌ Firebase 업데이트 실패, 디바운스로 재시도: $e');
        _scheduleDatabaseSync();
      }
    }
  }

  Future<void> deleteDiaryEntry(String id) async {
    await init();

    _cachedEntries.remove(id);

    // 로컬 저장
    await _saveLocalDiaryEntries();

    if (_firebaseAvailable) {
      try {
        await _userDiariesRef.child(id).remove();
        debugPrint('[DiaryService] ✅ Firebase에서 삭제: $id');
      } catch (e) {
        debugPrint('[DiaryService] ❌ Firebase 삭제 실패: $e');
      }
    }
  }

  // 앱 종료 시 동기화
  Future<void> syncOnAppClose() async {
    if (_firebaseAvailable && _hasPendingChanges) {
      await _syncToFirebase();
    }
  }

  // 수동 전체 동기화 (설정에서 호출 가능)
  Future<void> forceSync() async {
    if (!_firebaseAvailable) return;

    // 로컬 → Firebase 업로드
    _hasPendingChanges = true;
    await _syncToFirebase();

    // Firebase → 로컬 병합
    await _mergeRemoteEntries();

    debugPrint('[DiaryService] ✅ 강제 동기화 완료');
  }

  bool isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  // === 암호화 헬퍼 ===

  DiaryEntry _encryptEntry(DiaryEntry entry) {
    return DiaryEntry(
      id: entry.id,
      date: entry.date,
      mood: entry.mood,
      content: _encryption.encrypt(entry.content, entry.id) ?? entry.content,
      positiveVersion: entry.positiveVersion != null
          ? _encryption.encrypt(entry.positiveVersion!, entry.id)
          : null,
      devilVersion: entry.devilVersion != null
          ? _encryption.encrypt(entry.devilVersion!, entry.id)
          : null,
    );
  }

  DiaryEntry _decryptEntry(DiaryEntry entry) {
    return DiaryEntry(
      id: entry.id,
      date: entry.date,
      mood: entry.mood,
      content: _encryption.decrypt(entry.content, entry.id) ?? entry.content,
      positiveVersion: entry.positiveVersion != null
          ? _encryption.decrypt(entry.positiveVersion!, entry.id)
          : null,
      devilVersion: entry.devilVersion != null
          ? _encryption.decrypt(entry.devilVersion!, entry.id)
          : null,
    );
  }

  Future<void> _migrateUnencryptedEntries() async {
    if (!_encryption.isEnabled) return;

    bool needsSave = false;
    for (final entry in _cachedEntries.values) {
      if (entry.content.isNotEmpty && !_encryption.isEncrypted(entry.content)) {
        needsSave = true;
        break;
      }
    }

    if (needsSave) {
      debugPrint('[DiaryService] 비암호화 데이터 마이그레이션 시작...');
      await _saveLocalDiaryEntries();
      if (_firebaseAvailable) {
        _hasPendingChanges = true;
        await _syncToFirebase();
      }
      debugPrint('[DiaryService] 마이그레이션 완료');
    }
  }
}
