import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ko'),
  ];

  // English translations
  static const Map<String, String> _localizedStrings = {
    'appTitle': 'Diary App',
    'settings': 'Settings',
    'logout': 'Logout',
    'theme': 'Theme',
    'font': 'Font',
    'selectTheme': 'Select Theme',
    'selectFont': 'Select Font',
    'diaryList': 'Diary List',
    'login': 'Login',
    'googleSignIn': 'Sign in with Google',
    'logoutConfirm': 'Are you sure you want to logout?',
    'colorSelected': 'Background color changed.',
    'fontSelected': 'Font changed.',
    'diaryEntry': 'Write Diary',
    'editDiary': 'Edit Diary',
    'positiveVersion': 'Positive Version:',
    'convertToPositive': 'Convert to Positive Version',
    'diaryHint': 'Enter your diary entry',
    'moodHappy': 'Happy',
    'moodSad': 'Sad',
    'moodNeutral': 'Neutral',
    'loginSubtitle': 'Warmly record your precious day',
    'noDiaries': 'No diary entries yet. Create your first entry!',
    'deleteConfirm': 'Delete Confirmation',
    'deleteDiaryConfirm': 'Are you sure you want to delete this diary entry?',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'networkOffline': 'Please check your network connection.',
    'loginError': 'An error occurred during login. Please try again.'
  };

  // Korean translations
  static const Map<String, String> _localizedStringsKo = {
    'appTitle': '다이어리 앱',
    'settings': '설정',
    'logout': '로그아웃',
    'theme': '테마',
    'font': '글꼴',
    'selectTheme': '테마 선택',
    'selectFont': '글꼴 선택',
    'diaryList': '일기 목록',
    'login': '로그인',
    'googleSignIn': 'Google로 로그인',
    'logoutConfirm': '정말 로그아웃 하시겠습니까?',
    'colorSelected': '배경색이 변경되었습니다.',
    'fontSelected': '글꼴이 변경되었습니다.',
    'diaryEntry': '일기 작성',
    'editDiary': '일기 수정',
    'positiveVersion': '긍정 버전:',
    'convertToPositive': '긍정 버전으로 변환',
    'diaryHint': '일기를 작성해주세요',
    'moodHappy': '행복',
    'moodSad': '슬픔',
    'moodNeutral': '보통',
    'loginSubtitle': '소중한 하루를 따뜻하게 기록하세요',
    'noDiaries': '아직 작성된 일기가 없습니다. 첫 일기를 작성해보세요!',
    'deleteConfirm': '삭제 확인',
    'deleteDiaryConfirm': '이 일기를 삭제하시겠습니까?',
    'cancel': '취소',
    'delete': '삭제',
    'networkOffline': '네트워크 연결을 확인해주세요.',
    'loginError': '로그인 중 오류가 발생했습니다. 다시 시도해주세요.'
  };

  String translate(String key) {
    if (locale.languageCode == 'ko') {
      return _localizedStringsKo[key] ?? _localizedStrings[key] ?? key;
    }
    return _localizedStrings[key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ko'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
