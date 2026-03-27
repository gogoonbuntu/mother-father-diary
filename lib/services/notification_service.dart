import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'dart:ui' as ui;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _enabledKey = 'daily_notification_enabled';
  static const int _dailyReminderId = 1001;

  // 알림 끄기 액션 ID
  static const String actionDisable = 'DISABLE_NOTIFICATION';

  /// 현재 디바이스 언어코드 가져오기
  String get _langCode {
    try {
      return ui.PlatformDispatcher.instance.locale.languageCode;
    } catch (_) {
      return 'ko';
    }
  }

  /// 로캘별 문자열 매핑
  Map<String, String> get _strings {
    switch (_langCode) {
      case 'ja':
        return {
          'dismiss': '閉じる',
          'channelName': '日記リマインダー',
          'channelDesc': '毎晩9時に日記作成をお知らせします',
          'body': '今日はどんな一日でしたか？書いてみましょう！📝',
          'msg1': '今日はどんな一日でしたか？ ✨',
          'msg2': '今日もお疲れさまです！日記を書きませんか？ 📝',
          'msg3': '一日の終わりに今日を記録しましょう 🌙',
          'msg4': '今日の話を聞かせてください！ 💜',
          'msg5': '寝る前に今日を振り返りませんか？ 🌟',
        };
      case 'fr':
        return {
          'dismiss': 'Ignorer',
          'channelName': 'Rappel journal',
          'channelDesc': 'Rappel quotidien à 21h pour écrire votre journal',
          'body': 'Comment était votre journée ? Écrivez-le ! 📝',
          'msg1': "Comment s'est passée votre journée ? ✨",
          'msg2': 'Bravo pour aujourd\'hui ! Prêt à écrire ? 📝',
          'msg3': 'Terminez la journée en notant vos moments 🌙',
          'msg4': 'Racontez-nous votre journée ! 💜',
          'msg5': 'Avant de dormir, revoyons la journée 🌟',
        };
      case 'en':
        return {
          'dismiss': 'Dismiss',
          'channelName': 'Diary Reminder',
          'channelDesc': 'Daily reminder to write your diary at 9 PM',
          'body': 'How was your day? Write it down! 📝',
          'msg1': 'How was your day? ✨',
          'msg2': 'Great job today! Ready to write your diary? 📝',
          'msg3': "End your day by recording today's moments 🌙",
          'msg4': 'Tell us about your day! 💜',
          'msg5': "Before you sleep, let's look back on today 🌟",
        };
      default: // ko
        return {
          'dismiss': '알림 끄기',
          'channelName': '일기 알림',
          'channelDesc': '매일 저녁 9시에 일기 작성을 알려드려요',
          'body': '오늘 하루는 어땠나요? 일기를 써보세요! 📝',
          'msg1': '오늘 하루는 어땠나요? ✨',
          'msg2': '오늘도 수고했어요! 일기 쓰러 가볼까요? 📝',
          'msg3': '하루를 마무리하며 오늘을 기록해보세요 🌙',
          'msg4': '오늘의 이야기를 들려주세요! 💜',
          'msg5': '잠들기 전, 오늘 하루를 돌아볼까요? 🌟',
        };
    }
  }

  /// 초기화
  Future<void> init() async {
    tz_data.initializeTimeZones();
    // 한국 시간대 설정
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          'diary_reminder',
          actions: [
            DarwinNotificationAction.plain(
              actionDisable,
              _strings['dismiss']!,
              options: {DarwinNotificationActionOption.destructive},
            ),
          ],
        ),
      ],
    );

    await _notifications.initialize(
      InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundResponse,
    );

    // Android 알림 액션 등록
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    // 저장된 설정에 따라 알림 스케줄
    final enabled = await isEnabled();
    if (enabled) {
      await scheduleDailyReminder();
    }
  }

  /// 알림 응답 핸들러
  static void _onNotificationResponse(NotificationResponse response) {
    if (response.actionId == actionDisable) {
      NotificationService().setEnabled(false);
    }
  }

  /// 백그라운드 알림 응답 핸들러
  @pragma('vm:entry-point')
  static void _onBackgroundResponse(NotificationResponse response) {
    if (response.actionId == actionDisable) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool(_enabledKey, false);
      });
      FlutterLocalNotificationsPlugin().cancel(_dailyReminderId);
    }
  }

  /// 알림 활성화 여부 확인
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  /// 알림 활성화/비활성화 설정
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);

    if (enabled) {
      await scheduleDailyReminder();
    } else {
      await cancelDailyReminder();
    }
  }

  /// 매일 저녁 9시 알림 스케줄
  Future<void> scheduleDailyReminder() async {
    final s = _strings;
    const title = '✨ Mother Father Diary';
    final body = s['body']!;

    final androidDetails = AndroidNotificationDetails(
      'diary_reminder',
      s['channelName']!,
      channelDescription: s['channelDesc']!,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      actions: [
        AndroidNotificationAction(
          actionDisable,
          s['dismiss']!,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'diary_reminder',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 다음 21:00 시간 계산
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      21,
      0,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      _dailyReminderId,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint('[알림] 매일 21:00 알림 스케줄 완료: $scheduledDate');
  }

  /// 알림 취소
  Future<void> cancelDailyReminder() async {
    await _notifications.cancel(_dailyReminderId);
    debugPrint('[알림] 일기 알림 취소됨');
  }

  /// 🧪 테스트 알림 즉시 발송 (관리자용)
  Future<void> showTestNotification() async {
    final s = _strings;

    final androidDetails = AndroidNotificationDetails(
      'diary_reminder',
      s['channelName']!,
      channelDescription: s['channelDesc']!,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      actions: [
        AndroidNotificationAction(
          actionDisable,
          s['dismiss']!,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'diary_reminder',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      9999,
      '✨ Mother Father Diary',
      s['body']!,
      details,
    );
    debugPrint('[알림] 🧪 테스트 알림 발송 완료');
  }
}
