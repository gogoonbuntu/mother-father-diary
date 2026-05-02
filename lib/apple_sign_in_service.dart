import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppleSignInService {
  /// Apple 로그인 + Firebase Auth 연동
  static Future<UserCredential?> signInWithApple() async {
    try {
      // Nonce 생성 (보안을 위해 필요)
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Apple 로그인 요청
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Firebase Auth 연동 - idToken과 rawNonce만 전달
      // (authorizationCode는 OAuth accessToken이 아니므로 전달하지 않음)
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      // Apple은 최초 로그인 시에만 이름을 제공하므로 displayName 업데이트
      if (userCredential.user != null &&
          (userCredential.user!.displayName == null ||
              userCredential.user!.displayName!.isEmpty)) {
        final fullName = [
          appleCredential.givenName,
          appleCredential.familyName,
        ].where((n) => n != null && n.isNotEmpty).join(' ');

        if (fullName.isNotEmpty) {
          await userCredential.user!.updateDisplayName(fullName);
        }
      }

      print('Apple 로그인 성공: ${userCredential.user!.displayName}');
      return userCredential;
    } catch (e) {
      // 사용자가 취소한 경우
      if (e is SignInWithAppleAuthorizationException &&
          e.code == AuthorizationErrorCode.canceled) {
        print('Apple 로그인이 취소되었습니다.');
        return null;
      }
      print('Apple Sign-In error: $e');
      // Firebase credential 실패 시 익명 로그인으로 fallback
      // 사용자가 앱을 정상 사용할 수 있도록 보장
      try {
        print('Apple Sign-In fallback: 익명 로그인 시도');
        final anonymousCredential =
            await FirebaseAuth.instance.signInAnonymously();
        print('Fallback 익명 로그인 성공');
        return anonymousCredential;
      } catch (fallbackError) {
        print('Fallback 익명 로그인도 실패: $fallbackError');
        return null;
      }
    }
  }

  /// 랜덤 nonce 생성
  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// SHA256 해시
  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
