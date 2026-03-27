// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'ダイアリーアプリ';

  @override
  String get settings => '設定';

  @override
  String get logout => 'ログアウト';

  @override
  String get theme => 'テーマ';

  @override
  String get font => 'フォント';

  @override
  String get selectTheme => 'テーマ選択';

  @override
  String get selectFont => 'フォント選択';

  @override
  String get diaryEntry => '日記を書く';

  @override
  String get diaryList => '日記一覧';

  @override
  String get login => 'ログイン';

  @override
  String get googleSignIn => 'Googleでログイン';

  @override
  String get logoutConfirm => '本当にログアウトしますか？';

  @override
  String get colorSelected => '背景色が変更されました。';

  @override
  String get fontSelected => 'フォントが変更されました。';

  @override
  String get editDiary => '日記を編集';

  @override
  String get positiveVersion => 'ポジティブ版:';

  @override
  String get convertToPositive => 'ポジティブ版に変換';

  @override
  String get diaryHint => '日記を入力してください';

  @override
  String get moodHappy => '幸せ';

  @override
  String get moodSad => '悲しい';

  @override
  String get moodNeutral => '普通';

  @override
  String get loginSubtitle => '大切な一日をあたたかく記録しましょう';

  @override
  String get noDiaries => 'まだ日記がありません。最初の日記を書いてみましょう！';

  @override
  String get hidePositive => 'ポジティブ版を隠す';

  @override
  String get showPositive => 'ポジティブ版を表示';

  @override
  String get positiveButton => 'ポジティブ版を生成';

  @override
  String get cancel => 'キャンセル';

  @override
  String get close => '閉じる';

  @override
  String get delete => '削除';

  @override
  String get confirm => 'OK';

  @override
  String get share => '共有';

  @override
  String get exitAppTitle => 'アプリ終了';

  @override
  String get exitAppContent => 'アプリを終了しますか？';

  @override
  String get exitAppConfirm => '終了';

  @override
  String get settingsTooltip => '設定';

  @override
  String get emptyDiaryTitle => 'まだ日記がありません';

  @override
  String get emptyDiarySubtitle => '下のボタンをタップして最初の日記を書きましょう！';

  @override
  String get newDiaryButton => '✏️ 新しい日記';

  @override
  String get deleteConfirmTitle => '削除確認';

  @override
  String get deleteConfirmContent => 'この日記を削除しますか？';

  @override
  String get angel => '天使';

  @override
  String get devil => '悪魔';

  @override
  String get angelComfort => '天使の慰め';

  @override
  String get devilEmpathy => '悪魔の共感';

  @override
  String get regenerateAngel => '慰めを再生成';

  @override
  String get viewAngel => '慰めを見る';

  @override
  String get regenerateDevil => '共感を再生成';

  @override
  String get viewDevil => '共感を見る';

  @override
  String get originalDiary => '元の日記';

  @override
  String get shareAsImageCard => '画像カードで共有';

  @override
  String regenerateConfirm(String label, String remaining) {
    return '新しい$label版を生成しますか？\n\n⚠️ 1回分を消費します。\n(残り: $remaining)';
  }

  @override
  String get regenerateButton => '再生成';

  @override
  String premiumLimitReached(int limit) {
    return '月$limit回のプレミアム回数をすべて使用しました。\n広告を見ると追加生成できます！';
  }

  @override
  String freeLimitReached(int limit) {
    return '1日$limit回の無料生成回数をすべて使用しました。';
  }

  @override
  String get watchAdToGenerate => '広告を見て1回生成';

  @override
  String get premiumSubscription => 'プレミアム (月300回)';

  @override
  String get ratingQuestion => 'この結果にどのくらい満足しましたか？';

  @override
  String get ratingBad => '悪い';

  @override
  String get ratingPoor => '残念';

  @override
  String get ratingOk => 'まあまあ';

  @override
  String get ratingGood => '良い！';

  @override
  String get ratingExcellent => '最高！';

  @override
  String get rateAndGet => '評価して1回もらう';

  @override
  String get ratingComplete => '評価完了！';

  @override
  String get ratingPrompt => 'この結果どうですか？';

  @override
  String remainingCountFree(int remaining, int limit) {
    return '$remaining/$limit 日';
  }

  @override
  String remainingCountPremium(int remaining, int limit) {
    return '$remaining/$limit 月';
  }

  @override
  String get sendFeedback => 'フィードバック';

  @override
  String get feedbackSubtitle => 'バグや改善アイデアを教えてください！';

  @override
  String get bugReport => 'バグ報告';

  @override
  String get improvementSuggestion => '改善提案';

  @override
  String get emailFallback => 'メールアプリを開けません。tmddud333@naver.comに直接ご連絡ください。';

  @override
  String bugReportTemplate(String os) {
    return 'こんにちは、\n\n[バグの説明]\n\n\n[再現手順]\n1. \n2. \n3. \n\n[デバイス情報]\n- OS: $os\n- アプリバージョン: 1.0.0\n';
  }

  @override
  String get improvementTemplate =>
      'こんにちは、\n\n[改善提案の内容]\n\n\n[期待される効果]\n\n\nよろしくお願いします！\n';

  @override
  String get diaryNotification => '日記リマインダー';

  @override
  String get notificationSubtitle => '毎晩9時に今日を振り返りましょう';

  @override
  String get testNotification => 'テスト通知を送る';

  @override
  String get dataProtection => 'データ保護';

  @override
  String get e2eEncryption => 'エンドツーエンド暗号化(E2EE)';

  @override
  String get notificationChannelName => '日記リマインダー';

  @override
  String get notificationChannelDesc => '毎晩9時に日記作成をお知らせします';

  @override
  String get notificationDismiss => '閉じる';

  @override
  String get notificationBody => '今日はどんな一日でしたか？書いてみましょう！📝';

  @override
  String get notificationMsg1 => '今日はどんな一日でしたか？ ✨';

  @override
  String get notificationMsg2 => '今日もお疲れさまです！日記を書きませんか？ 📝';

  @override
  String get notificationMsg3 => '一日の終わりに今日を記録しましょう 🌙';

  @override
  String get notificationMsg4 => '今日の話を聞かせてください！ 💜';

  @override
  String get notificationMsg5 => '寝る前に今日を振り返りませんか？ 🌟';

  @override
  String get networkError => 'ネットワーク接続を確認してください。';

  @override
  String get loginError => 'ログイン中にエラーが発生しました。もう一度お試しください。';

  @override
  String get privacyTitle => 'あなたの日記は\n安全に保護されています';

  @override
  String get privacySubtitle => 'エンドツーエンド暗号化(E2EE)適用';

  @override
  String get privacyHowTitle => 'どのように暗号化されますか？';

  @override
  String get privacyHowBullet1 => '日記の内容はデバイスでAES-256軍事級暗号化で変換されます';

  @override
  String get privacyHowBullet2 => '暗号化された状態でサーバーに保存されるため、サーバーでは文字化けのみが表示されます';

  @override
  String get privacyHowBullet3 => '開発者を含む誰もその内容を確認できません';

  @override
  String get privacyKeyTitle => '暗号化キーはどのように保護されますか？';

  @override
  String get privacyKeyBullet1 => '暗号化キーはGoogleアカウント情報から自動生成されます';

  @override
  String get privacyKeyBullet2 => 'キーはデバイスメモリにのみ存在し、どこにも保存されません';

  @override
  String get privacyKeyBullet3 => '同じGoogleアカウントでログインすると常に同じキーが生成されます';

  @override
  String get privacyReassureTitle => 'ご安心ください';

  @override
  String get privacyRememberTitle => '必ず覚えてください';

  @override
  String get privacyRememberContent => '日記の内容は復元できません。Googleアカウントを安全に保ってください。';

  @override
  String get privacyTechSpecTitle => '技術仕様';

  @override
  String get privacySpecEncryption => '暗号化アルゴリズム';

  @override
  String get privacySpecKeyDerivation => '鍵導出';

  @override
  String get privacySpecDataId => 'データ識別';

  @override
  String get premiumRestore => '購入を復元';

  @override
  String get premiumTitle => 'プレミアム 月300回';

  @override
  String get premiumMonthly => '月額プラン';

  @override
  String get premiumMonthlyDesc => 'いつでも解約可能';

  @override
  String get premiumYearly => '年額プラン';

  @override
  String get premiumYearlyDesc => '月¥492 · 55%お得';

  @override
  String get premiumLifetime => '永久プラン';

  @override
  String get premiumLifetimeDesc => '一度の支払いで永遠に';

  @override
  String get premiumDisclaimer =>
      'サブスクリプションはiTunes/Google Playアカウントを通じて課金され、\n自動更新を解除しない場合、現在の期間終了の24時間前に\n自動的に更新されます。';

  @override
  String get premiumBenefit1 => '月300回AI日記変換';

  @override
  String get premiumBenefit2 => '広告なしで即利用';

  @override
  String get premiumBenefit3 => '天使＆悪魔バージョン両方使用';

  @override
  String get premiumBenefit4 => '高速AI応答優先処理';

  @override
  String get premiumComingSoon => '現在準備中です。もうすぐご利用いただけます！ 🚀';

  @override
  String get premiumNoRestore => '復元できる購入はありません。';

  @override
  String get shareCardBranding => 'AI日記を書いてみよう ✍️';

  @override
  String get shareCardAppName => 'ママパパダイアリー';
}
