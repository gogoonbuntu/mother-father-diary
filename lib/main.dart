import 'package:flutter/material.dart';
import 'package:diary_app/diary_entry_screen.dart';
import 'package:diary_app/diary_list_screen.dart';
import 'package:diary_app/services/diary_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:diary_app/opening_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DiaryService().init();
  // 광고 SDK 초기화
  await MobileAds.instance.initialize();
  print('[광고] MobileAds SDK 초기화 완료');
  runApp(const MyApp());
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
      home: _showOpening
          ? OpeningBanner(onFinish: _finishOpening)
          : const MainScreen(),
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
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: const [
          DiaryEntryScreen(),
          DiaryListScreen(),
        ],
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: '일기 쓰기'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: '일기 목록'),
        ],
      ),
    );
  }
}
