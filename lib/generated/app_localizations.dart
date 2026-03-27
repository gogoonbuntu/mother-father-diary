import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('ja'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Diary App'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @font.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get font;

  /// No description provided for @selectTheme.
  ///
  /// In en, this message translates to:
  /// **'Select Theme'**
  String get selectTheme;

  /// No description provided for @selectFont.
  ///
  /// In en, this message translates to:
  /// **'Select Font'**
  String get selectFont;

  /// No description provided for @diaryEntry.
  ///
  /// In en, this message translates to:
  /// **'Write Diary'**
  String get diaryEntry;

  /// No description provided for @diaryList.
  ///
  /// In en, this message translates to:
  /// **'Diary List'**
  String get diaryList;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @googleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get googleSignIn;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @colorSelected.
  ///
  /// In en, this message translates to:
  /// **'Background color changed.'**
  String get colorSelected;

  /// No description provided for @fontSelected.
  ///
  /// In en, this message translates to:
  /// **'Font changed.'**
  String get fontSelected;

  /// No description provided for @editDiary.
  ///
  /// In en, this message translates to:
  /// **'Edit Diary'**
  String get editDiary;

  /// No description provided for @positiveVersion.
  ///
  /// In en, this message translates to:
  /// **'Positive Version:'**
  String get positiveVersion;

  /// No description provided for @convertToPositive.
  ///
  /// In en, this message translates to:
  /// **'Convert to Positive Version'**
  String get convertToPositive;

  /// No description provided for @diaryHint.
  ///
  /// In en, this message translates to:
  /// **'Write your diary here'**
  String get diaryHint;

  /// No description provided for @moodHappy.
  ///
  /// In en, this message translates to:
  /// **'Happy'**
  String get moodHappy;

  /// No description provided for @moodSad.
  ///
  /// In en, this message translates to:
  /// **'Sad'**
  String get moodSad;

  /// No description provided for @moodNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get moodNeutral;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Warmly record your precious day'**
  String get loginSubtitle;

  /// No description provided for @noDiaries.
  ///
  /// In en, this message translates to:
  /// **'No diary entries yet. Create your first entry!'**
  String get noDiaries;

  /// No description provided for @hidePositive.
  ///
  /// In en, this message translates to:
  /// **'Hide Positive Version'**
  String get hidePositive;

  /// No description provided for @showPositive.
  ///
  /// In en, this message translates to:
  /// **'Show Positive Version'**
  String get showPositive;

  /// No description provided for @positiveButton.
  ///
  /// In en, this message translates to:
  /// **'Generate Positive Version'**
  String get positiveButton;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get confirm;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @exitAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit App'**
  String get exitAppTitle;

  /// No description provided for @exitAppContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit?'**
  String get exitAppContent;

  /// No description provided for @exitAppConfirm.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exitAppConfirm;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @emptyDiaryTitle.
  ///
  /// In en, this message translates to:
  /// **'No diary entries yet'**
  String get emptyDiaryTitle;

  /// No description provided for @emptyDiarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to write your first diary!'**
  String get emptyDiarySubtitle;

  /// No description provided for @newDiaryButton.
  ///
  /// In en, this message translates to:
  /// **'✏️ New Diary'**
  String get newDiaryButton;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this diary?'**
  String get deleteConfirmContent;

  /// No description provided for @angel.
  ///
  /// In en, this message translates to:
  /// **'Angel'**
  String get angel;

  /// No description provided for @devil.
  ///
  /// In en, this message translates to:
  /// **'Devil'**
  String get devil;

  /// No description provided for @angelComfort.
  ///
  /// In en, this message translates to:
  /// **'Angel\'s Comfort'**
  String get angelComfort;

  /// No description provided for @devilEmpathy.
  ///
  /// In en, this message translates to:
  /// **'Devil\'s Empathy'**
  String get devilEmpathy;

  /// No description provided for @regenerateAngel.
  ///
  /// In en, this message translates to:
  /// **'Regenerate Comfort'**
  String get regenerateAngel;

  /// No description provided for @viewAngel.
  ///
  /// In en, this message translates to:
  /// **'View Comfort'**
  String get viewAngel;

  /// No description provided for @regenerateDevil.
  ///
  /// In en, this message translates to:
  /// **'Regenerate Empathy'**
  String get regenerateDevil;

  /// No description provided for @viewDevil.
  ///
  /// In en, this message translates to:
  /// **'View Empathy'**
  String get viewDevil;

  /// No description provided for @originalDiary.
  ///
  /// In en, this message translates to:
  /// **'Original Diary'**
  String get originalDiary;

  /// No description provided for @shareAsImageCard.
  ///
  /// In en, this message translates to:
  /// **'Share as Image Card'**
  String get shareAsImageCard;

  /// No description provided for @regenerateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Generate a new {label} version?\n\n⚠️ This will use 1 credit.\n(Remaining: {remaining})'**
  String regenerateConfirm(String label, String remaining);

  /// No description provided for @regenerateButton.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get regenerateButton;

  /// No description provided for @premiumLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used all {limit} premium credits this month.\nWatch an ad for an extra generation!'**
  String premiumLimitReached(int limit);

  /// No description provided for @freeLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used all {limit} free credits today.'**
  String freeLimitReached(int limit);

  /// No description provided for @watchAdToGenerate.
  ///
  /// In en, this message translates to:
  /// **'Watch ad for 1 free generation'**
  String get watchAdToGenerate;

  /// No description provided for @premiumSubscription.
  ///
  /// In en, this message translates to:
  /// **'Premium Subscription (300/mo)'**
  String get premiumSubscription;

  /// No description provided for @ratingQuestion.
  ///
  /// In en, this message translates to:
  /// **'How satisfied were you with this result?'**
  String get ratingQuestion;

  /// No description provided for @ratingBad.
  ///
  /// In en, this message translates to:
  /// **'Bad'**
  String get ratingBad;

  /// No description provided for @ratingPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get ratingPoor;

  /// No description provided for @ratingOk.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get ratingOk;

  /// No description provided for @ratingGood.
  ///
  /// In en, this message translates to:
  /// **'Good!'**
  String get ratingGood;

  /// No description provided for @ratingExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent!'**
  String get ratingExcellent;

  /// No description provided for @rateAndGet.
  ///
  /// In en, this message translates to:
  /// **'Rate & get 1 credit'**
  String get rateAndGet;

  /// No description provided for @ratingComplete.
  ///
  /// In en, this message translates to:
  /// **'Rating complete!'**
  String get ratingComplete;

  /// No description provided for @ratingPrompt.
  ///
  /// In en, this message translates to:
  /// **'How was this result?'**
  String get ratingPrompt;

  /// No description provided for @remainingCountFree.
  ///
  /// In en, this message translates to:
  /// **'{remaining}/{limit} daily'**
  String remainingCountFree(int remaining, int limit);

  /// No description provided for @remainingCountPremium.
  ///
  /// In en, this message translates to:
  /// **'{remaining}/{limit} monthly'**
  String remainingCountPremium(int remaining, int limit);

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// No description provided for @feedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Report a bug or share your ideas!'**
  String get feedbackSubtitle;

  /// No description provided for @bugReport.
  ///
  /// In en, this message translates to:
  /// **'Bug Report'**
  String get bugReport;

  /// No description provided for @improvementSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get improvementSuggestion;

  /// No description provided for @emailFallback.
  ///
  /// In en, this message translates to:
  /// **'Cannot open email app. Please email tmddud333@naver.com directly.'**
  String get emailFallback;

  /// No description provided for @bugReportTemplate.
  ///
  /// In en, this message translates to:
  /// **'Hello,\n\n[Bug Description]\n\n\n[Steps to Reproduce]\n1. \n2. \n3. \n\n[Device Info]\n- OS: {os}\n- App Version: 1.0.0\n'**
  String bugReportTemplate(String os);

  /// No description provided for @improvementTemplate.
  ///
  /// In en, this message translates to:
  /// **'Hello,\n\n[Improvement Suggestion]\n\n\n[Expected Benefits]\n\n\nThank you!\n'**
  String get improvementTemplate;

  /// No description provided for @diaryNotification.
  ///
  /// In en, this message translates to:
  /// **'Diary Reminder'**
  String get diaryNotification;

  /// No description provided for @notificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get a reminder every evening at 9 PM'**
  String get notificationSubtitle;

  /// No description provided for @testNotification.
  ///
  /// In en, this message translates to:
  /// **'Send Test Notification'**
  String get testNotification;

  /// No description provided for @dataProtection.
  ///
  /// In en, this message translates to:
  /// **'Data Protection'**
  String get dataProtection;

  /// No description provided for @e2eEncryption.
  ///
  /// In en, this message translates to:
  /// **'End-to-end Encryption (E2EE)'**
  String get e2eEncryption;

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Diary Reminder'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder to write your diary at 9 PM'**
  String get notificationChannelDesc;

  /// No description provided for @notificationDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get notificationDismiss;

  /// No description provided for @notificationBody.
  ///
  /// In en, this message translates to:
  /// **'How was your day? Write it down! 📝'**
  String get notificationBody;

  /// No description provided for @notificationMsg1.
  ///
  /// In en, this message translates to:
  /// **'How was your day? ✨'**
  String get notificationMsg1;

  /// No description provided for @notificationMsg2.
  ///
  /// In en, this message translates to:
  /// **'Great job today! Ready to write your diary? 📝'**
  String get notificationMsg2;

  /// No description provided for @notificationMsg3.
  ///
  /// In en, this message translates to:
  /// **'End your day by recording today\'s moments 🌙'**
  String get notificationMsg3;

  /// No description provided for @notificationMsg4.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your day! 💜'**
  String get notificationMsg4;

  /// No description provided for @notificationMsg5.
  ///
  /// In en, this message translates to:
  /// **'Before you sleep, let\'s look back on today 🌟'**
  String get notificationMsg5;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Please check your network connection.'**
  String get networkError;

  /// No description provided for @loginError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred during login. Please try again.'**
  String get loginError;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your diary is\nsafely protected'**
  String get privacyTitle;

  /// No description provided for @privacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'End-to-end Encryption (E2EE) Applied'**
  String get privacySubtitle;

  /// No description provided for @privacyHowTitle.
  ///
  /// In en, this message translates to:
  /// **'How is it encrypted?'**
  String get privacyHowTitle;

  /// No description provided for @privacyHowBullet1.
  ///
  /// In en, this message translates to:
  /// **'Your diary is encrypted on device with AES-256 military-grade encryption'**
  String get privacyHowBullet1;

  /// No description provided for @privacyHowBullet2.
  ///
  /// In en, this message translates to:
  /// **'Data is stored encrypted on the server — only scrambled text is visible'**
  String get privacyHowBullet2;

  /// No description provided for @privacyHowBullet3.
  ///
  /// In en, this message translates to:
  /// **'No one, including the developer, can read your entries'**
  String get privacyHowBullet3;

  /// No description provided for @privacyKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'How is the encryption key protected?'**
  String get privacyKeyTitle;

  /// No description provided for @privacyKeyBullet1.
  ///
  /// In en, this message translates to:
  /// **'The encryption key is automatically generated from your Google account'**
  String get privacyKeyBullet1;

  /// No description provided for @privacyKeyBullet2.
  ///
  /// In en, this message translates to:
  /// **'The key exists only in device memory and is never stored anywhere'**
  String get privacyKeyBullet2;

  /// No description provided for @privacyKeyBullet3.
  ///
  /// In en, this message translates to:
  /// **'Logging in with the same Google account always generates the same key'**
  String get privacyKeyBullet3;

  /// No description provided for @privacyReassureTitle.
  ///
  /// In en, this message translates to:
  /// **'Rest assured'**
  String get privacyReassureTitle;

  /// No description provided for @privacyRememberTitle.
  ///
  /// In en, this message translates to:
  /// **'Please remember'**
  String get privacyRememberTitle;

  /// No description provided for @privacyRememberContent.
  ///
  /// In en, this message translates to:
  /// **'Diary contents cannot be recovered. Please keep your Google account safe.'**
  String get privacyRememberContent;

  /// No description provided for @privacyTechSpecTitle.
  ///
  /// In en, this message translates to:
  /// **'Technical Specifications'**
  String get privacyTechSpecTitle;

  /// No description provided for @privacySpecEncryption.
  ///
  /// In en, this message translates to:
  /// **'Encryption Algorithm'**
  String get privacySpecEncryption;

  /// No description provided for @privacySpecKeyDerivation.
  ///
  /// In en, this message translates to:
  /// **'Key Derivation'**
  String get privacySpecKeyDerivation;

  /// No description provided for @privacySpecDataId.
  ///
  /// In en, this message translates to:
  /// **'Data Identifier'**
  String get privacySpecDataId;

  /// No description provided for @premiumRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchase'**
  String get premiumRestore;

  /// No description provided for @premiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium 300/month'**
  String get premiumTitle;

  /// No description provided for @premiumMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get premiumMonthly;

  /// No description provided for @premiumMonthlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime'**
  String get premiumMonthlyDesc;

  /// No description provided for @premiumYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get premiumYearly;

  /// No description provided for @premiumYearlyDesc.
  ///
  /// In en, this message translates to:
  /// **'₩492/mo · Save 55%'**
  String get premiumYearlyDesc;

  /// No description provided for @premiumLifetime.
  ///
  /// In en, this message translates to:
  /// **'Lifetime'**
  String get premiumLifetime;

  /// No description provided for @premiumLifetimeDesc.
  ///
  /// In en, this message translates to:
  /// **'One-time payment, forever'**
  String get premiumLifetimeDesc;

  /// No description provided for @premiumDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions are charged through your iTunes/Google Play account.\nIf auto-renewal is not cancelled, it will automatically renew\n24 hours before the end of the current period.'**
  String get premiumDisclaimer;

  /// No description provided for @premiumBenefit1.
  ///
  /// In en, this message translates to:
  /// **'300 AI diary conversions/month'**
  String get premiumBenefit1;

  /// No description provided for @premiumBenefit2.
  ///
  /// In en, this message translates to:
  /// **'No ads, instant access'**
  String get premiumBenefit2;

  /// No description provided for @premiumBenefit3.
  ///
  /// In en, this message translates to:
  /// **'Both Angel & Devil versions'**
  String get premiumBenefit3;

  /// No description provided for @premiumBenefit4.
  ///
  /// In en, this message translates to:
  /// **'Priority AI response speed'**
  String get premiumBenefit4;

  /// No description provided for @premiumComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon! Stay tuned! 🚀'**
  String get premiumComingSoon;

  /// No description provided for @premiumNoRestore.
  ///
  /// In en, this message translates to:
  /// **'No purchases to restore.'**
  String get premiumNoRestore;

  /// No description provided for @shareCardBranding.
  ///
  /// In en, this message translates to:
  /// **'Try AI Diary too ✍️'**
  String get shareCardBranding;

  /// No description provided for @shareCardAppName.
  ///
  /// In en, this message translates to:
  /// **'Mom Dad Diary'**
  String get shareCardAppName;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr', 'ja', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
