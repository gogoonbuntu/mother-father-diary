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
  String get diaryHint => 'Write your diary here';

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

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get delete => 'Delete';

  @override
  String get confirm => 'OK';

  @override
  String get share => 'Share';

  @override
  String get exitAppTitle => 'Exit App';

  @override
  String get exitAppContent => 'Are you sure you want to exit?';

  @override
  String get exitAppConfirm => 'Exit';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get emptyDiaryTitle => 'No diary entries yet';

  @override
  String get emptyDiarySubtitle =>
      'Tap the button below to write your first diary!';

  @override
  String get newDiaryButton => '✏️ New Diary';

  @override
  String get deleteConfirmTitle => 'Confirm Delete';

  @override
  String get deleteConfirmContent =>
      'Are you sure you want to delete this diary?';

  @override
  String get angel => 'Angel';

  @override
  String get devil => 'Devil';

  @override
  String get angelComfort => 'Angel\'s Comfort';

  @override
  String get devilEmpathy => 'Devil\'s Empathy';

  @override
  String get regenerateAngel => 'Regenerate Comfort';

  @override
  String get viewAngel => 'View Comfort';

  @override
  String get regenerateDevil => 'Regenerate Empathy';

  @override
  String get viewDevil => 'View Empathy';

  @override
  String get originalDiary => 'Original Diary';

  @override
  String get shareAsImageCard => 'Share as Image Card';

  @override
  String regenerateConfirm(String label, String remaining) {
    return 'Generate a new $label version?\n\n⚠️ This will use 1 credit.\n(Remaining: $remaining)';
  }

  @override
  String get regenerateButton => 'Regenerate';

  @override
  String premiumLimitReached(int limit) {
    return 'You\'ve used all $limit premium credits this month.\nWatch an ad for an extra generation!';
  }

  @override
  String freeLimitReached(int limit) {
    return 'You\'ve used all $limit free credits today.';
  }

  @override
  String get watchAdToGenerate => 'Watch ad for 1 free generation';

  @override
  String get premiumSubscription => 'Premium Subscription (300/mo)';

  @override
  String get ratingQuestion => 'How satisfied were you with this result?';

  @override
  String get ratingBad => 'Bad';

  @override
  String get ratingPoor => 'Poor';

  @override
  String get ratingOk => 'Okay';

  @override
  String get ratingGood => 'Good!';

  @override
  String get ratingExcellent => 'Excellent!';

  @override
  String get rateAndGet => 'Rate & get 1 credit';

  @override
  String get ratingComplete => 'Rating complete!';

  @override
  String get ratingPrompt => 'How was this result?';

  @override
  String remainingCountFree(int remaining, int limit) {
    return '$remaining/$limit daily';
  }

  @override
  String remainingCountPremium(int remaining, int limit) {
    return '$remaining/$limit monthly';
  }

  @override
  String get sendFeedback => 'Send Feedback';

  @override
  String get feedbackSubtitle => 'Report a bug or share your ideas!';

  @override
  String get bugReport => 'Bug Report';

  @override
  String get improvementSuggestion => 'Suggestion';

  @override
  String get emailFallback =>
      'Cannot open email app. Please email tmddud333@naver.com directly.';

  @override
  String bugReportTemplate(String os) {
    return 'Hello,\n\n[Bug Description]\n\n\n[Steps to Reproduce]\n1. \n2. \n3. \n\n[Device Info]\n- OS: $os\n- App Version: 1.0.0\n';
  }

  @override
  String get improvementTemplate =>
      'Hello,\n\n[Improvement Suggestion]\n\n\n[Expected Benefits]\n\n\nThank you!\n';

  @override
  String get diaryNotification => 'Diary Reminder';

  @override
  String get notificationSubtitle => 'Get a reminder every evening at 9 PM';

  @override
  String get testNotification => 'Send Test Notification';

  @override
  String get dataProtection => 'Data Protection';

  @override
  String get e2eEncryption => 'End-to-end Encryption (E2EE)';

  @override
  String get notificationChannelName => 'Diary Reminder';

  @override
  String get notificationChannelDesc =>
      'Daily reminder to write your diary at 9 PM';

  @override
  String get notificationDismiss => 'Dismiss';

  @override
  String get notificationBody => 'How was your day? Write it down! 📝';

  @override
  String get notificationMsg1 => 'How was your day? ✨';

  @override
  String get notificationMsg2 =>
      'Great job today! Ready to write your diary? 📝';

  @override
  String get notificationMsg3 =>
      'End your day by recording today\'s moments 🌙';

  @override
  String get notificationMsg4 => 'Tell us about your day! 💜';

  @override
  String get notificationMsg5 =>
      'Before you sleep, let\'s look back on today 🌟';

  @override
  String get networkError => 'Please check your network connection.';

  @override
  String get loginError => 'An error occurred during login. Please try again.';

  @override
  String get privacyTitle => 'Your diary is\nsafely protected';

  @override
  String get privacySubtitle => 'End-to-end Encryption (E2EE) Applied';

  @override
  String get privacyHowTitle => 'How is it encrypted?';

  @override
  String get privacyHowBullet1 =>
      'Your diary is encrypted on device with AES-256 military-grade encryption';

  @override
  String get privacyHowBullet2 =>
      'Data is stored encrypted on the server — only scrambled text is visible';

  @override
  String get privacyHowBullet3 =>
      'No one, including the developer, can read your entries';

  @override
  String get privacyKeyTitle => 'How is the encryption key protected?';

  @override
  String get privacyKeyBullet1 =>
      'The encryption key is automatically generated from your Google account';

  @override
  String get privacyKeyBullet2 =>
      'The key exists only in device memory and is never stored anywhere';

  @override
  String get privacyKeyBullet3 =>
      'Logging in with the same Google account always generates the same key';

  @override
  String get privacyReassureTitle => 'Rest assured';

  @override
  String get privacyRememberTitle => 'Please remember';

  @override
  String get privacyRememberContent =>
      'Diary contents cannot be recovered. Please keep your Google account safe.';

  @override
  String get privacyTechSpecTitle => 'Technical Specifications';

  @override
  String get privacySpecEncryption => 'Encryption Algorithm';

  @override
  String get privacySpecKeyDerivation => 'Key Derivation';

  @override
  String get privacySpecDataId => 'Data Identifier';

  @override
  String get premiumRestore => 'Restore Purchase';

  @override
  String get premiumTitle => 'Premium 300/month';

  @override
  String get premiumMonthly => 'Monthly';

  @override
  String get premiumMonthlyDesc => 'Cancel anytime';

  @override
  String get premiumYearly => 'Yearly';

  @override
  String get premiumYearlyDesc => '₩492/mo · Save 55%';

  @override
  String get premiumLifetime => 'Lifetime';

  @override
  String get premiumLifetimeDesc => 'One-time payment, forever';

  @override
  String get premiumDisclaimer =>
      'Subscriptions are charged through your iTunes/Google Play account.\nIf auto-renewal is not cancelled, it will automatically renew\n24 hours before the end of the current period.';

  @override
  String get premiumBenefit1 => '300 AI diary conversions/month';

  @override
  String get premiumBenefit2 => 'No ads, instant access';

  @override
  String get premiumBenefit3 => 'Both Angel & Devil versions';

  @override
  String get premiumBenefit4 => 'Priority AI response speed';

  @override
  String get premiumComingSoon => 'Coming soon! Stay tuned! 🚀';

  @override
  String get premiumNoRestore => 'No purchases to restore.';

  @override
  String get shareCardBranding => 'Try AI Diary too ✍️';

  @override
  String get shareCardAppName => 'Mom Dad Diary';

  @override
  String get appleSignIn => 'Sign in with Apple';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountSubtitle =>
      'Permanently delete your account and all data';

  @override
  String get deleteAccountWarning1 =>
      'Are you sure you want to delete your account?\n\nAll diary entries and data will be permanently deleted and cannot be recovered.';

  @override
  String get deleteAccountContinue => 'Continue';

  @override
  String get deleteAccountFinalTitle => 'Final Confirmation';

  @override
  String get deleteAccountWarning2 =>
      'This action cannot be undone. All your diary entries, settings, and account information will be permanently deleted.\n\nAre you sure you want to continue?';

  @override
  String get deleteAccountConfirm => 'Delete Account Permanently';

  @override
  String get deleteAccountError =>
      'An error occurred while deleting the account. Please try again.';
}
