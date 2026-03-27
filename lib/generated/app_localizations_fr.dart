// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Journal Intime';

  @override
  String get settings => 'Paramètres';

  @override
  String get logout => 'Déconnexion';

  @override
  String get theme => 'Thème';

  @override
  String get font => 'Police';

  @override
  String get selectTheme => 'Choisir un thème';

  @override
  String get selectFont => 'Choisir une police';

  @override
  String get diaryEntry => 'Écrire';

  @override
  String get diaryList => 'Liste des entrées';

  @override
  String get login => 'Connexion';

  @override
  String get googleSignIn => 'Se connecter avec Google';

  @override
  String get logoutConfirm => 'Voulez-vous vraiment vous déconnecter ?';

  @override
  String get colorSelected => 'Couleur de fond modifiée.';

  @override
  String get fontSelected => 'Police modifiée.';

  @override
  String get editDiary => 'Modifier';

  @override
  String get positiveVersion => 'Version positive :';

  @override
  String get convertToPositive => 'Convertir en version positive';

  @override
  String get diaryHint => 'Écrivez votre journal ici';

  @override
  String get moodHappy => 'Heureux';

  @override
  String get moodSad => 'Triste';

  @override
  String get moodNeutral => 'Neutre';

  @override
  String get loginSubtitle =>
      'Enregistrez chaleureusement votre précieuse journée';

  @override
  String get noDiaries =>
      'Aucune entrée pour le moment. Créez votre première entrée !';

  @override
  String get hidePositive => 'Masquer la version positive';

  @override
  String get showPositive => 'Afficher la version positive';

  @override
  String get positiveButton => 'Générer la version positive';

  @override
  String get cancel => 'Annuler';

  @override
  String get close => 'Fermer';

  @override
  String get delete => 'Supprimer';

  @override
  String get confirm => 'OK';

  @override
  String get share => 'Partager';

  @override
  String get exitAppTitle => 'Quitter l\'app';

  @override
  String get exitAppContent => 'Voulez-vous vraiment quitter ?';

  @override
  String get exitAppConfirm => 'Quitter';

  @override
  String get settingsTooltip => 'Paramètres';

  @override
  String get emptyDiaryTitle => 'Aucune entrée pour le moment';

  @override
  String get emptyDiarySubtitle =>
      'Appuyez sur le bouton ci-dessous pour écrire votre premier journal !';

  @override
  String get newDiaryButton => '✏️ Nouveau journal';

  @override
  String get deleteConfirmTitle => 'Confirmer la suppression';

  @override
  String get deleteConfirmContent => 'Voulez-vous supprimer cette entrée ?';

  @override
  String get angel => 'Ange';

  @override
  String get devil => 'Diable';

  @override
  String get angelComfort => 'Réconfort de l\'Ange';

  @override
  String get devilEmpathy => 'Empathie du Diable';

  @override
  String get regenerateAngel => 'Régénérer le réconfort';

  @override
  String get viewAngel => 'Voir le réconfort';

  @override
  String get regenerateDevil => 'Régénérer l\'empathie';

  @override
  String get viewDevil => 'Voir l\'empathie';

  @override
  String get originalDiary => 'Journal original';

  @override
  String get shareAsImageCard => 'Partager en carte image';

  @override
  String regenerateConfirm(String label, String remaining) {
    return 'Générer une nouvelle version $label ?\n\n⚠️ 1 crédit sera utilisé.\n(Restant : $remaining)';
  }

  @override
  String get regenerateButton => 'Régénérer';

  @override
  String premiumLimitReached(int limit) {
    return 'Vous avez utilisé vos $limit crédits premium ce mois-ci.\nRegardez une pub pour une génération supplémentaire !';
  }

  @override
  String freeLimitReached(int limit) {
    return 'Vous avez utilisé vos $limit crédits gratuits aujourd\'hui.';
  }

  @override
  String get watchAdToGenerate => 'Regarder une pub pour 1 génération';

  @override
  String get premiumSubscription => 'Abonnement Premium (300/mois)';

  @override
  String get ratingQuestion => 'Êtes-vous satisfait de ce résultat ?';

  @override
  String get ratingBad => 'Mauvais';

  @override
  String get ratingPoor => 'Décevant';

  @override
  String get ratingOk => 'Correct';

  @override
  String get ratingGood => 'Bien !';

  @override
  String get ratingExcellent => 'Excellent !';

  @override
  String get rateAndGet => 'Évaluer et obtenir 1 crédit';

  @override
  String get ratingComplete => 'Évaluation terminée !';

  @override
  String get ratingPrompt => 'Comment trouvez-vous ce résultat ?';

  @override
  String remainingCountFree(int remaining, int limit) {
    return '$remaining/$limit jour';
  }

  @override
  String remainingCountPremium(int remaining, int limit) {
    return '$remaining/$limit mois';
  }

  @override
  String get sendFeedback => 'Envoyer un avis';

  @override
  String get feedbackSubtitle => 'Signalez un bug ou partagez vos idées !';

  @override
  String get bugReport => 'Rapport de bug';

  @override
  String get improvementSuggestion => 'Suggestion';

  @override
  String get emailFallback =>
      'Impossible d\'ouvrir l\'app mail. Envoyez un email à tmddud333@naver.com.';

  @override
  String bugReportTemplate(String os) {
    return 'Bonjour,\n\n[Description du bug]\n\n\n[Étapes de reproduction]\n1. \n2. \n3. \n\n[Infos appareil]\n- OS : $os\n- Version : 1.0.0\n';
  }

  @override
  String get improvementTemplate =>
      'Bonjour,\n\n[Suggestion d\'amélioration]\n\n\n[Bénéfices attendus]\n\n\nMerci !\n';

  @override
  String get diaryNotification => 'Rappel journal';

  @override
  String get notificationSubtitle => 'Un rappel chaque soir à 21h';

  @override
  String get testNotification => 'Envoyer une notification test';

  @override
  String get dataProtection => 'Protection des données';

  @override
  String get e2eEncryption => 'Chiffrement de bout en bout (E2EE)';

  @override
  String get notificationChannelName => 'Rappel journal';

  @override
  String get notificationChannelDesc =>
      'Rappel quotidien à 21h pour écrire votre journal';

  @override
  String get notificationDismiss => 'Ignorer';

  @override
  String get notificationBody =>
      'Comment était votre journée ? Écrivez-le ! 📝';

  @override
  String get notificationMsg1 => 'Comment s\'est passée votre journée ? ✨';

  @override
  String get notificationMsg2 => 'Bravo pour aujourd\'hui ! Prêt à écrire ? 📝';

  @override
  String get notificationMsg3 => 'Terminez la journée en notant vos moments 🌙';

  @override
  String get notificationMsg4 => 'Racontez-nous votre journée ! 💜';

  @override
  String get notificationMsg5 => 'Avant de dormir, revoyons la journée 🌟';

  @override
  String get networkError => 'Vérifiez votre connexion réseau.';

  @override
  String get loginError =>
      'Une erreur est survenue lors de la connexion. Réessayez.';

  @override
  String get privacyTitle => 'Votre journal est\nen sécurité';

  @override
  String get privacySubtitle => 'Chiffrement de bout en bout (E2EE)';

  @override
  String get privacyHowTitle => 'Comment est-il chiffré ?';

  @override
  String get privacyHowBullet1 =>
      'Votre journal est chiffré sur l\'appareil avec AES-256 de niveau militaire';

  @override
  String get privacyHowBullet2 =>
      'Les données sont stockées chiffrées — seul du texte illisible est visible sur le serveur';

  @override
  String get privacyHowBullet3 =>
      'Personne, y compris le développeur, ne peut lire vos entrées';

  @override
  String get privacyKeyTitle =>
      'Comment la clé de chiffrement est-elle protégée ?';

  @override
  String get privacyKeyBullet1 =>
      'La clé est automatiquement générée à partir de votre compte Google';

  @override
  String get privacyKeyBullet2 =>
      'La clé n\'existe que dans la mémoire de l\'appareil et n\'est jamais stockée';

  @override
  String get privacyKeyBullet3 =>
      'Se connecter avec le même compte Google génère toujours la même clé';

  @override
  String get privacyReassureTitle => 'Soyez tranquille';

  @override
  String get privacyRememberTitle => 'N\'oubliez pas';

  @override
  String get privacyRememberContent =>
      'Le contenu du journal ne peut pas être récupéré. Gardez votre compte Google en sécurité.';

  @override
  String get privacyTechSpecTitle => 'Spécifications techniques';

  @override
  String get privacySpecEncryption => 'Algorithme de chiffrement';

  @override
  String get privacySpecKeyDerivation => 'Dérivation de clé';

  @override
  String get privacySpecDataId => 'Identifiant de données';

  @override
  String get premiumRestore => 'Restaurer l\'achat';

  @override
  String get premiumTitle => 'Premium 300/mois';

  @override
  String get premiumMonthly => 'Mensuel';

  @override
  String get premiumMonthlyDesc => 'Résiliable à tout moment';

  @override
  String get premiumYearly => 'Annuel';

  @override
  String get premiumYearlyDesc => '492₩/mois · Économisez 55%';

  @override
  String get premiumLifetime => 'À vie';

  @override
  String get premiumLifetimeDesc => 'Un seul paiement, pour toujours';

  @override
  String get premiumDisclaimer =>
      'Les abonnements sont facturés via votre compte iTunes/Google Play.\nSi le renouvellement automatique n\'est pas annulé, il sera renouvelé\n24 heures avant la fin de la période en cours.';

  @override
  String get premiumBenefit1 => '300 conversions IA/mois';

  @override
  String get premiumBenefit2 => 'Sans publicité';

  @override
  String get premiumBenefit3 => 'Versions Ange et Diable';

  @override
  String get premiumBenefit4 => 'Réponse IA prioritaire';

  @override
  String get premiumComingSoon => 'Bientôt disponible ! 🚀';

  @override
  String get premiumNoRestore => 'Aucun achat à restaurer.';

  @override
  String get shareCardBranding => 'Essayez le journal IA ✍️';

  @override
  String get shareCardAppName => 'Journal Papa Maman';
}
