import 'package:flutter/material.dart';
import 'package:prefmon/globals.dart';
import 'package:prefmon/screens/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Globals.sharedPreferences = await SharedPreferences.getInstance();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Backbone Performance Monitor',
      theme: ThemeData.dark(),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
