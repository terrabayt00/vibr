import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:magic_control/firebase_options.dart';
import 'package:magic_control/screens/home/home_screen.dart';
import 'package:magic_control/style/brand_color.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Magic control',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                backgroundColor: BrandColor.kGreen,
                foregroundColor: Colors.white)),
      ),
      home: const HomeScreen(),
    );
  }
}
