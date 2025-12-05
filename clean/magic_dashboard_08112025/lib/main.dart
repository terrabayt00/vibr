import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:magic_dashbord/data/app_data.dart';
import 'package:magic_dashbord/firebase_options.dart';
import 'package:magic_dashbord/screen/root_screen.dart';
import 'package:magic_dashbord/style/brand_color.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppData(),
      child: MaterialApp(
        title: 'Sofa Room',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: BrandColor.kRed),
          useMaterial3: true,
          elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColor.kGreen,
                  foregroundColor: Colors.white)),
        ),
        home: const MyRootWidget(),
      ),
    );
  }
}
