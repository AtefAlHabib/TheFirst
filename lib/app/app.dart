import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../home/home_page.dart';
import 'StoragePermissionManager.dart';

class MyApp extends StatefulWidget {
  final Function(ThemeMode) changeThemeMode;

  MyApp({Key? key, required this.changeThemeMode}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  void _changeThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  void initState() {
    super.initState();

    // استدعاء تهيئة الصلاحيات بعد تأكيد تحميل الواجهة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // انتظر فترة كافية (3 ثواني) لضمان تحميل MaterialApp بالكامل
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _navigatorKey.currentContext != null) {
         // print('🎯 بدء طلب الصلاحيات بعد تحميل التطبيق');

          // عرض فلترتوست لتتبع العملية


          // استدعاء مدير الصلاحيات مع السياق الصحيح
          StoragePermissionManager().initializePermissions(_navigatorKey.currentContext!);
        }
      });
    }

    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey, // المهم جداً
      debugShowCheckedModeBanner: false,
      title: 'Flutter App',
      themeMode: _themeMode,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: Color(0xFFF8FAFC),
        fontFamily: 'Calibri',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0),
            ),
            backgroundColor: Color(0xFFD9EAFD),
            foregroundColor: Color(0xFF353B3E),
            textStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Calibri',
            ),
            elevation: 2,
            padding: EdgeInsets.zero,
          ),
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Calibri',
            color: Color(0xFF141617),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Calibri',
            color: Color(0xFF2C3134),
          ),
          filled: true,
          fillColor: Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Color(0xFF26282D)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Color(0xFF26282D), width: 2),
          ),
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF352F44),
        fontFamily: 'Calibri',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0),
            ),
            backgroundColor: Color(0xFF5C5470),
            foregroundColor: Color(0xFFFAF0E6),
            textStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Calibri',
            ),
            elevation: 2,
            padding: EdgeInsets.zero,
          ),
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Calibri',
            color: Color(0xFFFAF0E6),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Calibri',
            color: Color(0xFFFAF0E6),
          ),
          filled: true,
          fillColor: Color(0xFF352F44),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Color(0xFFFAF0E6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Color(0xFFFAF0E6), width: 2),
          ),
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
      ),
      home: MyHomePage(changeThemeMode: _changeThemeMode),
    );
  }
}