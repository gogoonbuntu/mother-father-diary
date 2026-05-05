import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:diary_app/generated/app_localizations.dart';
import 'package:diary_app/login_screen.dart';
import 'package:diary_app/opening_banner.dart';
import 'package:diary_app/settings_screen.dart';

import 'package:diary_app/diary_entry_screen.dart';
import 'package:diary_app/diary_list_screen.dart';
import 'package:diary_app/services/diary_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart'; // 한글 글씨체 사용을 위한 패키지 추가
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'package:clarity_flutter/clarity_flutter.dart';
import 'services/notification_service.dart';
import 'services/purchase_service.dart';
// [중요] firebase_options.dart 파일은 flutterfire CLI로 생성된 실제 파일로 교체해야 합니다.
// 현재 파일이 비어있거나 DefaultFirebaseOptions가 없다면 앱이 실행되지 않습니다.


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // iOS에서 GoogleService-Info.plist가 자동으로 초기화하는 경우
    // [core/duplicate-app] 에러를 무시
    if (Firebase.apps.isEmpty) rethrow;
    debugPrint('[Firebase] 이미 초기화됨: $e');
  }

  // Microsoft Clarity 초기화
  final clarityConfig = ClarityConfig(
    projectId: "vqwdhsd5ex",
    logLevel: LogLevel.None,
  );

  // 서비스 초기화를 먼저 완료한 후 앱 실행
  await Future.wait([
    DiaryService().init(),
    PurchaseService().initialize(),
    NotificationService().init(),
    MobileAds.instance.initialize().then((_) {
      debugPrint('[광고] MobileAds SDK 초기화 완료');
    }),
  ]);
  debugPrint('[초기화] 모든 서비스 초기화 완료');

  runApp(ClarityWidget(
    app: const MyApp(),
    clarityConfig: clarityConfig,
  ));
}

// 지원되는 Google Fonts 통합 목록 (한글 완벽 지원 폰트만)
const List<String> kSupportedFonts = [
  'Jua',
  'Gamja Flower',
  'Poor Story',
  'Nanum Gothic',
  'Nanum Myeongjo',
];


// 글로벌 폰트 알림 — MyApp이 이를 감시하여 MaterialApp 테마 전체에 적용
final globalFontNotifier = ValueNotifier<String>('Nanum Gothic');

// 글로벌 로캘 알림 — null이면 시스템 기본 사용
final globalLocaleNotifier = ValueNotifier<Locale?>(null);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showOpening = true;

  @override
  void initState() {
    super.initState();
    globalFontNotifier.addListener(_onSettingChanged);
    globalLocaleNotifier.addListener(_onSettingChanged);
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('app_locale');
    if (code != null) {
      globalLocaleNotifier.value = Locale(code);
    }
  }

  @override
  void dispose() {
    globalFontNotifier.removeListener(_onSettingChanged);
    globalLocaleNotifier.removeListener(_onSettingChanged);
    super.dispose();
  }

  void _onSettingChanged() {
    setState(() {}); // MaterialApp 테마/로캘 재빌드
  }

  void _finishOpening() {
    setState(() {
      _showOpening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fontFamily = globalFontNotifier.value;
    debugPrint('[폰트] 선택된 폰트: $fontFamily');

    return MaterialApp(
      title: 'Diary App',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C5CFC),
          brightness: Brightness.light,
          primary: const Color(0xFF7C5CFC),
          secondary: const Color(0xFFFF8FAB),
          surface: const Color(0xFFF8F5FF),
          onSurface: const Color(0xFF2D2D3A),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F5FF),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          foregroundColor: const Color(0xFF2D2D3A),
          titleTextStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2D2D3A),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: globalLocaleNotifier.value,
      localeResolutionCallback: (locale, supportedLocales) {
        // 유저가 명시적으로 선택한 경우 그대로 사용
        if (globalLocaleNotifier.value != null) {
          return globalLocaleNotifier.value;
        }
        for (var supportedLocale in supportedLocales) {
          if (locale?.languageCode == supportedLocale.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },
      // 모든 페이지/라우트에 선택된 폰트 강제 적용 (번들 폰트)
      builder: (context, child) {
        return DefaultTextStyle.merge(
          style: TextStyle(fontFamily: fontFamily),
          child: child!,
        );
      },

      home: _showOpening
          ? OpeningBanner(onFinish: _finishOpening)
          : StreamBuilder(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasData) {
                  return const MainScreen();
                } else {
                  return const LoginScreen();
                }
              },
            ),
    );
  }
}


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {



  // 테마/색상 상태를 MainScreen에서 관리
  Color _bgColor = const Color(0xFFFFE0E6);
  String _fontFamily = 'Nanum Gothic';
  bool _settingsLoaded = false;

  static const List<Color> _colorOptions = [
    Color(0xFFFFE0E6), // 소프트 핑크
    Color(0xFFFFF2E0), // 워므 크림
    Color(0xFFE0F5E9), // 민트
    Color(0xFFE8E0FF), // 라벤더
    Color(0xFFE0EDFF), // 스카이 블루
    Color(0xFFFAF4E6), // 아이보리
  ];

  // Google Fonts를 통해 사용할 글씨체 목록 - 통합 목록 사용
  static final List<String> _fontOptions = kSupportedFonts.toList();

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  /// Firebase + SharedPreferences에서 사용자 설정 로드
  Future<void> _loadUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedFont = prefs.getString('user_font');
    final savedColor = prefs.getInt('user_bg_color');
    
    // 로컬 캐시에서 먼저 불러오기
    if (savedFont != null || savedColor != null) {
      setState(() {
        if (savedFont != null) {
          _fontFamily = kSupportedFonts.contains(savedFont) ? savedFont : 'Nanum Gothic';
        }
        if (savedColor != null) _bgColor = Color(savedColor);
        _settingsLoaded = true;
      });
      globalFontNotifier.value = _fontFamily;
    }
    
    // Firebase에서 동기화
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseDatabase.instance
            .ref('users/${user.uid}/settings')
            .get();
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          setState(() {
            if (data['fontFamily'] != null) {
              final fbFont = data['fontFamily'] as String;
              _fontFamily = kSupportedFonts.contains(fbFont) ? fbFont : 'Nanum Gothic';
            }
            if (data['bgColor'] != null) _bgColor = Color(data['bgColor'] as int);
            _settingsLoaded = true;
          });
          globalFontNotifier.value = _fontFamily;
          // 로컬 캐시 업데이트
          await prefs.setString('user_font', _fontFamily);
          await prefs.setInt('user_bg_color', _bgColor.toARGB32());
        }
      }
    } catch (e) {
      debugPrint('[설정] Firebase 로드 실패: $e');
    }
    if (!_settingsLoaded) setState(() => _settingsLoaded = true);
  }

  /// 설정 저장 (SharedPreferences + Firebase)
  Future<void> _saveUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_font', _fontFamily);
    await prefs.setInt('user_bg_color', _bgColor.toARGB32());
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseDatabase.instance
            .ref('users/${user.uid}/settings')
            .set({
          'fontFamily': _fontFamily,
          'bgColor': _bgColor.toARGB32(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('[설정] Firebase 저장 실패: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.exitAppTitle),
            content: Text(AppLocalizations.of(context)!.exitAppContent),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(AppLocalizations.of(context)!.exitAppConfirm),
              ),
            ],
          ),
        );
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C5CFC), Color(0xFF9B7DFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            boxShadow: [BoxShadow(color: const Color(0xFF7C5CFC).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              '✨ 럭키비키 일기장',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: 0.5),
            ),
            centerTitle: true,
            actions: [
  IconButton(
    icon: const Icon(Icons.settings),
    tooltip: AppLocalizations.of(context)!.settingsTooltip,
    onPressed: () async {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SettingsScreen(
            currentColor: _bgColor,
            colorOptions: _colorOptions,
            currentFont: _fontFamily,
            fontOptions: _fontOptions,
            onColorSelected: (color) {
              setState(() => _bgColor = color);
              _saveUserSettings();
            },
            onFontSelected: (font) {
              setState(() => _fontFamily = font);
              globalFontNotifier.value = font;
              _saveUserSettings();
            },
          ),
        ),
      );
    },
  ),
],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: _bgColor,
        ),
        child: DiaryListScreen(bgColor: _bgColor, fontFamily: _fontFamily),
      ),
    ),
    );
  }
}
