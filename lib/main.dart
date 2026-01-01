import 'package:flutter/material.dart';
import 'app/app.dart'; // استيراد MyApp فقط

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp(
    changeThemeMode: (mode) {}, // دالة تغيير الثيم
  ));
}