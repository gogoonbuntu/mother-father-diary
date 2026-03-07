import 'dart:convert';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// AES-256-CBC 기반 일기 암호화 서비스
/// 키는 Google UID + 앱 고유 salt로 결정적 파생 → 키 분실 불가
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  // 앱 고유 salt (변경 금지 — 변경 시 기존 데이터 복호화 불가)
  static const String _appSalt = 'MotherFatherDiary_E2EE_2026_v1';

  enc.Key? _key;
  bool _initialized = false;

  /// 현재 사용자 UID 기반으로 키 초기화
  void initialize() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      debugPrint('[암호화] 사용자 UID 없음 — 암호화 비활성화');
      _initialized = false;
      return;
    }
    _key = _deriveKey(uid);
    _initialized = true;
    debugPrint('[암호화] AES-256 키 파생 완료 (UID 기반)');
  }

  /// 암호화가 활성화되어 있는지 확인
  bool get isEnabled => _initialized && _key != null;

  /// UID + salt → SHA-256 → AES-256 키 (32바이트)
  enc.Key _deriveKey(String uid) {
    // PBKDF2 대신 SHA-256(uid + salt)를 2회 해싱하여 키 파생
    // SHA-256은 항상 32바이트 → AES-256에 정확히 맞음
    final round1 = sha256.convert(utf8.encode('$uid:$_appSalt'));
    final round2 = sha256.convert(utf8.encode('${round1.toString()}:$_appSalt:$uid'));
    return enc.Key(Uint8List.fromList(round2.bytes));
  }

  /// 고정 IV 생성 (entryId 기반, 항상 같은 결과)
  enc.IV _deriveIV(String entryId) {
    final hash = md5.convert(utf8.encode('$entryId:$_appSalt'));
    return enc.IV(Uint8List.fromList(hash.bytes)); // MD5 = 16바이트 = IV 크기
  }

  /// 평문 → 암호화 텍스트 (Base64)
  /// entryId를 IV 생성에 사용하여 같은 내용도 일기마다 다른 암호문
  String? encrypt(String plainText, String entryId) {
    if (!isEnabled || plainText.isEmpty) return plainText;
    try {
      final iv = _deriveIV(entryId);
      final encrypter = enc.Encrypter(enc.AES(_key!, mode: enc.AESMode.cbc, padding: 'PKCS7'));
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      // 접두사 'E2E:' 추가하여 암호화된 텍스트 식별
      return 'E2E:${encrypted.base64}';
    } catch (e) {
      debugPrint('[암호화] 암호화 실패: $e');
      return plainText; // 실패 시 평문 반환
    }
  }

  /// 암호화 텍스트 (Base64) → 평문
  String? decrypt(String? cipherText, String entryId) {
    if (cipherText == null || cipherText.isEmpty) return cipherText;
    // 암호화되지 않은 텍스트인 경우 그대로 반환
    if (!cipherText.startsWith('E2E:')) return cipherText;
    if (!isEnabled) {
      debugPrint('[암호화] 키 미초기화 — 복호화 불가');
      return cipherText;
    }
    try {
      final iv = _deriveIV(entryId);
      final encrypter = enc.Encrypter(enc.AES(_key!, mode: enc.AESMode.cbc, padding: 'PKCS7'));
      final base64Data = cipherText.substring(4); // 'E2E:' 접두사 제거
      return encrypter.decrypt64(base64Data, iv: iv);
    } catch (e) {
      debugPrint('[암호화] 복호화 실패: $e');
      return cipherText; // 실패 시 암호화된 텍스트 그대로 반환
    }
  }

  /// 텍스트가 암호화되어 있는지 확인
  bool isEncrypted(String? text) {
    return text != null && text.startsWith('E2E:');
  }
}
