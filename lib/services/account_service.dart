import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

/// 계정 삭제 서비스 — Apple App Store 가이드라인 5.1.1(v) 준수
class AccountService {
  /// 계정 및 모든 관련 데이터 영구 삭제
  /// 
  /// 삭제 순서:
  /// 1. Firebase Realtime Database에서 사용자 데이터 삭제
  /// 2. 로컬 일기 파일 삭제
  /// 3. SharedPreferences 초기화
  /// 4. Firebase Auth 계정 삭제
  /// 5. Google Sign-In 세션 정리
  static Future<void> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('로그인된 사용자가 없습니다.');

    final uid = user.uid;

    // 1. Firebase Realtime Database에서 사용자 데이터 삭제
    try {
      final dbRef = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://diary-becbb-default-rtdb.asia-southeast1.firebasedatabase.app',
      ).ref();
      await dbRef.child('users/$uid').remove();
      debugPrint('[AccountService] ✅ Firebase 데이터 삭제 완료');
    } catch (e) {
      debugPrint('[AccountService] ⚠️ Firebase 데이터 삭제 실패: $e');
      // 계속 진행 — 나머지 삭제 작업도 수행
    }

    // 2. 로컬 일기 파일 삭제
    try {
      final directory = await getApplicationDocumentsDirectory();
      final diaryFile = File('${directory.path}/diary_entries_$uid.json');
      if (await diaryFile.exists()) {
        await diaryFile.delete();
        debugPrint('[AccountService] ✅ 로컬 일기 파일 삭제 완료');
      }
    } catch (e) {
      debugPrint('[AccountService] ⚠️ 로컬 파일 삭제 실패: $e');
    }

    // 3. SharedPreferences 초기화
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('[AccountService] ✅ SharedPreferences 초기화 완료');
    } catch (e) {
      debugPrint('[AccountService] ⚠️ SharedPreferences 초기화 실패: $e');
    }

    // 4. Firebase Auth 계정 삭제
    try {
      await user.delete();
      debugPrint('[AccountService] ✅ Firebase Auth 계정 삭제 완료');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        debugPrint('[AccountService] ⚠️ 재인증 필요');
        rethrow; // 호출자에서 재인증 후 재시도하도록
      }
      rethrow;
    }

    // 5. Google Sign-In 세션 정리
    try {
      await GoogleSignIn().signOut();
      debugPrint('[AccountService] ✅ Google Sign-In 세션 정리 완료');
    } catch (e) {
      debugPrint('[AccountService] ⚠️ Google Sign-In 정리 실패: $e');
    }

    debugPrint('[AccountService] ✅ 계정 삭제 완전 완료');
  }

  /// Google 계정으로 재인증
  static Future<bool> reauthenticateWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn(scopes: ['email']).signIn();
      if (googleUser == null) return false;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.currentUser?.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      debugPrint('[AccountService] 재인증 실패: $e');
      return false;
    }
  }
}
