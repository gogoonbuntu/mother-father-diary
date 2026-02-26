// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Diary App';

  @override
  String get settings => 'Settings';

  @override
  String get logout => 'Logout';

  @override
  String get theme => 'Theme';

  @override
  String get font => 'Font';

  @override
  String get selectTheme => 'Select Theme';

  @override
  String get selectFont => 'Select Font';

  @override
  String get diaryEntry => 'Write Diary';

  @override
  String get diaryList => 'Diary List';

  @override
  String get login => 'Login';

  @override
  String get googleSignIn => 'Sign in with Google';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  @override
  String get colorSelected => 'Background color changed.';

  @override
  String get fontSelected => 'Font changed.';

  @override
  String get editDiary => 'Edit Diary';

  @override
  String get positiveVersion => 'Positive Version:';

  @override
  String get convertToPositive => 'Convert to Positive Version';

  @override
  String get diaryHint => 'Enter your diary entry';

  @override
  String get moodHappy => 'Happy';

  @override
  String get moodSad => 'Sad';

  @override
  String get moodNeutral => 'Neutral';

  @override
  String get loginSubtitle => 'Warmly record your precious day';

  @override
  String get noDiaries => 'No diary entries yet. Create your first entry!';

  @override
  String get hidePositive => 'Hide Positive Version';

  @override
  String get showPositive => 'Show Positive Version';

  @override
  String get positiveButton => 'Generate Positive Version';
}
