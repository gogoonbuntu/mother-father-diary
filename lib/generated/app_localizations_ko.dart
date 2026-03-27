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

  @override
  String get cancel => '취소';

  @override
  String get close => '닫기';

  @override
  String get delete => '삭제';

  @override
  String get confirm => '확인';

  @override
  String get share => '공유하기';

  @override
  String get exitAppTitle => '앱 종료';

  @override
  String get exitAppContent => '앱을 종료하시겠습니까?';

  @override
  String get exitAppConfirm => '종료';

  @override
  String get settingsTooltip => '설정';

  @override
  String get emptyDiaryTitle => '아직 일기가 없어요';

  @override
  String get emptyDiarySubtitle => '아래 버튼을 눌러 첫 일기를 작성해보세요!';

  @override
  String get newDiaryButton => '✏️ 새 일기 쓰기';

  @override
  String get deleteConfirmTitle => '삭제 확인';

  @override
  String get deleteConfirmContent => '이 일기를 삭제하시겠습니까?';

  @override
  String get angel => '천사';

  @override
  String get devil => '악마';

  @override
  String get angelComfort => '천사의 위로';

  @override
  String get devilEmpathy => '악마의 공감';

  @override
  String get regenerateAngel => '위로 재생성';

  @override
  String get viewAngel => '위로 보기';

  @override
  String get regenerateDevil => '공감 재생성';

  @override
  String get viewDevil => '공감 보기';

  @override
  String get originalDiary => '원본 일기';

  @override
  String get shareAsImageCard => '이미지 카드로 공유하기';

  @override
  String regenerateConfirm(String label, String remaining) {
    return '새로운 $label 버전을 생성하시겠습니까?\n\n⚠️ 1회가 소모됩니다.\n(남은 횟수: $remaining)';
  }

  @override
  String get regenerateButton => '재생성';

  @override
  String premiumLimitReached(int limit) {
    return '월 $limit회 프리미엄 횟수를 모두 사용했습니다.\n광고를 보면 추가 생성할 수 있어요!';
  }

  @override
  String freeLimitReached(int limit) {
    return '하루 $limit회 무료 생성 횟수를 모두 사용했습니다.';
  }

  @override
  String get watchAdToGenerate => '광고 보고 1회 생성하기';

  @override
  String get premiumSubscription => '프리미엄 구독 (월 300회)';

  @override
  String get ratingQuestion => '이 결과가 얼마나 만족스러웠나요?';

  @override
  String get ratingBad => '별로예요';

  @override
  String get ratingPoor => '아쉬워요';

  @override
  String get ratingOk => '괜찮아요';

  @override
  String get ratingGood => '좋아요!';

  @override
  String get ratingExcellent => '최고예요!';

  @override
  String get rateAndGet => '평가하고 1회 받기';

  @override
  String get ratingComplete => '평가 완료!';

  @override
  String get ratingPrompt => '이 결과 어때요?';

  @override
  String remainingCountFree(int remaining, int limit) {
    return '$remaining/$limit 일';
  }

  @override
  String remainingCountPremium(int remaining, int limit) {
    return '$remaining/$limit 월';
  }

  @override
  String get sendFeedback => '의견 보내기';

  @override
  String get feedbackSubtitle => '버그나 개선 아이디어를 알려주세요!';

  @override
  String get bugReport => '버그 리포트';

  @override
  String get improvementSuggestion => '개선 제안';

  @override
  String get emailFallback =>
      '이메일 앱을 열 수 없습니다. tmddud333@naver.com 으로 직접 보내주세요.';

  @override
  String bugReportTemplate(String os) {
    return '안녕하세요,\n\n[버그 설명]\n\n\n[재현 방법]\n1. \n2. \n3. \n\n[기기 정보]\n- OS: $os\n- 앱 버전: 1.0.0\n';
  }

  @override
  String get improvementTemplate =>
      '안녕하세요,\n\n[개선 제안 내용]\n\n\n[기대 효과]\n\n\n감사합니다!\n';

  @override
  String get diaryNotification => '일기 알림';

  @override
  String get notificationSubtitle => '매일 저녁 9시에 오늘 하루를 물어봐요';

  @override
  String get testNotification => '테스트 알림 보내기';

  @override
  String get dataProtection => '데이터 보호';

  @override
  String get e2eEncryption => '종단간 암호화(E2EE) 적용';

  @override
  String get notificationChannelName => '일기 알림';

  @override
  String get notificationChannelDesc => '매일 저녁 9시에 일기 작성을 알려드려요';

  @override
  String get notificationDismiss => '알림 끄기';

  @override
  String get notificationBody => '오늘 하루는 어땠나요? 일기를 써보세요! 📝';

  @override
  String get notificationMsg1 => '오늘 하루는 어땠나요? ✨';

  @override
  String get notificationMsg2 => '오늘도 수고했어요! 일기 쓰러 가볼까요? 📝';

  @override
  String get notificationMsg3 => '하루를 마무리하며 오늘을 기록해보세요 🌙';

  @override
  String get notificationMsg4 => '오늘의 이야기를 들려주세요! 💜';

  @override
  String get notificationMsg5 => '잠들기 전, 오늘 하루를 돌아볼까요? 🌟';

  @override
  String get networkError => '네트워크 연결을 확인해주세요.';

  @override
  String get loginError => '로그인 중 오류가 발생했습니다. 다시 시도해주세요.';

  @override
  String get privacyTitle => '당신의 일기는\n안전하게 보호됩니다';

  @override
  String get privacySubtitle => '종단간 암호화(E2EE) 적용';

  @override
  String get privacyHowTitle => '어떻게 암호화되나요?';

  @override
  String get privacyHowBullet1 => '일기 내용은 기기에서 AES-256 군사급 암호화로 변환됩니다';

  @override
  String get privacyHowBullet2 => '암호화된 상태로 서버에 저장되므로, 서버에서는 깨진 문자만 보입니다';

  @override
  String get privacyHowBullet3 => '개발자를 포함한 그 누구도 내용을 확인할 수 없습니다';

  @override
  String get privacyKeyTitle => '암호화 키는 어떻게 보호되나요?';

  @override
  String get privacyKeyBullet1 => '암호화 키는 Google 계정 정보로부터 자동 생성됩니다';

  @override
  String get privacyKeyBullet2 => '키는 기기 메모리에만 존재하며, 어디에도 저장되지 않습니다';

  @override
  String get privacyKeyBullet3 => '같은 Google 계정으로 로그인하면 항상 같은 키가 생성됩니다';

  @override
  String get privacyReassureTitle => '안심하세요';

  @override
  String get privacyRememberTitle => '꼭 기억해주세요';

  @override
  String get privacyRememberContent =>
      '일기 내용을 복구할 수 없습니다. Google 계정을 안전하게 유지해주세요.';

  @override
  String get privacyTechSpecTitle => '기술 사양';

  @override
  String get privacySpecEncryption => '암호화 알고리즘';

  @override
  String get privacySpecKeyDerivation => '키 파생';

  @override
  String get privacySpecDataId => '데이터 식별';

  @override
  String get premiumRestore => '구매 복원';

  @override
  String get premiumTitle => '프리미엄 월 300회';

  @override
  String get premiumMonthly => '월간 구독';

  @override
  String get premiumMonthlyDesc => '언제든 해지 가능';

  @override
  String get premiumYearly => '연간 구독';

  @override
  String get premiumYearlyDesc => '월 ₩492 · 55% 절약';

  @override
  String get premiumLifetime => '평생 이용권';

  @override
  String get premiumLifetimeDesc => '한 번 결제로 영원히';

  @override
  String get premiumDisclaimer =>
      '구독은 iTunes/Google Play 계정을 통해 결제되며,\n자동 갱신을 해지 않으면 구독 기간 종료 24시간 전에\n자동으로 갱신됩니다.';

  @override
  String get premiumBenefit1 => '월 300회 AI 일기 변환';

  @override
  String get premiumBenefit2 => '광고 없이 바로 사용';

  @override
  String get premiumBenefit3 => '천사 & 악마 버전 모두 사용';

  @override
  String get premiumBenefit4 => '빠른 AI 응답 우선 처리';

  @override
  String get premiumComingSoon => '현재 준비 중입니다. 곧 이용 가능합니다! 🚀';

  @override
  String get premiumNoRestore => '복원할 구매 내역이 없습니다.';

  @override
  String get shareCardBranding => '나도 AI 일기 써보기 ✍️';

  @override
  String get shareCardAppName => '엄마아빠 다이어리';
}
