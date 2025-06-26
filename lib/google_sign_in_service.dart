import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class GoogleSignInService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Google 로그인 + Firebase Auth 연동
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // 네트워크 연결 확인
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception('network_offline');
      }
      // 1. Google 로그인
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // 로그인 취소 시

      // 타입 체크: 예상치 못한 타입 반환 시 예외 처리
      if (googleUser is! GoogleSignInAccount) {
        print('구글 로그인 반환값 타입 오류: ${googleUser.runtimeType}');
        throw TypeError();
      }
      final googleAuth = await googleUser.authentication;

      // 2. Firebase Auth 연동
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      // 로그인 성공 시 오류 메시지가 표시되지 않도록 성공 여부 확인
      if (userCredential.user != null) {
        print('로그인 성공: ${userCredential.user!.displayName}');
        return userCredential;
      } else {
        throw Exception('로그인 실패: 사용자 정보를 가져올 수 없습니다.');
      }
    } catch (e, stack) {
      print('Google Sign-In with Firebase Auth error: $e');
      print('Stacktrace: $stack');
      rethrow;
    }
  }

  static Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      return account;
    } catch (error) {
      print('Google sign-in error: $error');
      return null;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
  }

  static GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
}
