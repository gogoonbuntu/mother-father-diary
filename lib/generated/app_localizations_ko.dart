// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '다이어리 앱';

  @override
  String get settings => '설정';

  @override
  String get logout => '로그아웃';

  @override
  String get theme => '테마';

  @override
  String get font => '폰트';

  @override
  String get selectTheme => '테마 선택';

  @override
  String get selectFont => '폰트 선택';

  @override
  String get diaryEntry => '일기 쓰기';

  @override
  String get diaryList => '일기 목록';

  @override
  String get login => '로그인';

  @override
  String get googleSignIn => '구글로 로그인';

  @override
  String get logoutConfirm => '정말 로그아웃 하시겠습니까?';

  @override
  String get colorSelected => '배경색이 변경되었습니다.';

  @override
  String get fontSelected => '폰트가 변경되었습니다.';

  @override
  String get editDiary => '일기 수정';

  @override
  String get positiveVersion => '긍정 버전:';

  @override
  String get convertToPositive => '긍정 버전으로 변환';

  @override
  String get diaryHint => '일기를 입력하세요';

  @override
  String get moodHappy => '행복';

  @override
  String get moodSad => '슬픔';

  @override
  String get moodNeutral => '보통';

  @override
  String get loginSubtitle => '소중한 하루를 따뜻하게 기록하세요';

  @override
  String get noDiaries => '아직 일기가 없습니다. 첫 번째 일기를 작성해보세요!';

  @override
  String get hidePositive => '긍정 버전 숨기기';

  @override
  String get showPositive => '긍정 버전 보기';

  @override
  String get positiveButton => '긍정 버전 생성하기';
}
