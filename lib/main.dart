import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:diary_app/generated/app_localizations.dart';
import 'package:diary_app/login_screen.dart';
import 'package:diary_app/opening_banner.dart';
import 'package:diary_app/settings_screen.dart';
import 'package:diary_app/google_sign_in_service.dart';
import 'package:diary_app/diary_entry_screen.dart';
import 'package:diary_app/diary_list_screen.dart';
import 'package:diary_app/services/diary_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart'; // 한글 글씨체 사용을 위한 패키지 추가
import 'firebase_options.dart';
// [중요] firebase_options.dart 파일은 flutterfire CLI로 생성된 실제 파일로 교체해야 합니다.
// 현재 파일이 비어있거나 DefaultFirebaseOptions가 없다면 앱이 실행되지 않습니다.


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Google Fonts 캐시 초기화 및 미리 로딩
  await _preloadGoogleFonts();
  await DiaryService().init();
  // 광고 SDK 초기화
  await MobileAds.instance.initialize();
  print('[광고] MobileAds SDK 초기화 완료');
  runApp(const MyApp());
}

// Google Fonts 미리 로딩 함수
Future<void> _preloadGoogleFonts() async {
  // 지원되는 폰트 목록
  final fontList = [
    'Roboto',      // 기본 영문 폰트
    'NotoSansKR',  // 한글 기본 폰트
    'NanumGothic', // 한글 기본 폰트
    'NanumMyeongjo', // 한글 글씨체
    'Jua',         // 한글 글씨체
    'GamjaFlower', // 한글 글씨체
    'DoHyeon',     // 한글 글씨체
    'PoorStory',   // 한글 글씨체
  ];
  
  for (final fontFamily in fontList) {
    try {
      await GoogleFonts.getFont(fontFamily);
      debugPrint('폰트 로딩 성공: $fontFamily');
    } catch (e) {
      debugPrint('폰트 로딩 실패: $fontFamily - $e');
      // 실패해도 계속 진행
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showOpening = true;

  void _finishOpening() {
    setState(() {
      _showOpening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diary App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: WidgetsBinding.instance.window.locale.languageCode == 'ko'
          ? const Locale('ko')
          : null,

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
  int _currentIndex = 0;
  late PageController _pageController;
  GoogleSignInAccount? _user;
  bool _loading = false;

  // 테마/색상 상태를 MainScreen에서 관리
  Color _bgColor = const Color(0xFFFFE0E6);
  String _fontFamily = 'NanumPenScript';

  static const List<Color> _colorOptions = [
    Color(0xFFFFE0E6), // soft pink
    Color(0xFFFFF2E0), // warm cream
    Color(0xFFFFB6A6), // peach
    Color(0xFFFFD6C0), // light apricot
    Color(0xFFFFB6B9), // pink
    Color(0xFFFFE6C0), // yellow-peach
    Color(0xFFFAF4E6), // ivory
    Color(0xFFF9E7E7), // light rose
  ];

  // Google Fonts를 통해 사용할 글씨체 목록 - 지원되는 폰트만 포함
  static const List<String> _fontOptions = [
    // 한글 글씨체
    'Jua',
    'DoHyeon',
    'GamjaFlower',
    'HiMelody',
    'EastSeaDokdo',
    'PoorStory',
    // 영어 글씨체
    'Roboto',
    'Lato',
    'OpenSans',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Diary App',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            centerTitle: true,
            actions: [
  IconButton(
    icon: const Icon(Icons.settings),
    tooltip: '설정',
    onPressed: () async {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SettingsScreen(
            currentColor: _bgColor,
            colorOptions: _colorOptions,
            currentFont: _fontFamily,
            fontOptions: _fontOptions,
            onColorSelected: (color) => setState(() => _bgColor = color),
            onFontSelected: (font) => setState(() => _fontFamily = font),
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFe0eafc), Color(0xFFcfdef3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          children: [
            DiaryEntryScreen(bgColor: _bgColor, fontFamily: _fontFamily),
            DiaryListScreen(bgColor: _bgColor, fontFamily: _fontFamily),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.edit), label: AppLocalizations.of(context)!.diaryEntry),
          BottomNavigationBarItem(icon: const Icon(Icons.list), label: AppLocalizations.of(context)!.diaryList),
        ],
      ),
    );
  }
}
