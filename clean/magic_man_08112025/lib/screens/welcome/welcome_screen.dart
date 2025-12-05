import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:magic/alarm/service_task.dart';
import 'package:magic/helpers/installed_apps_helper.dart';
import 'package:magic/screens/home/home_page.dart';
import 'package:magic/style/color/brand_color.dart';
import 'package:magic/style/color/brand_text.dart';
import 'package:magic/utils/permission.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/device_helper.dart';
import '../../helpers/device_info_helper.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _signInAnonAndSync(); // Perform Firebase anonymous sign-in on screen load
  }

  /// Signs in the user anonymously with Firebase and triggers device/app sync
  Future<void> _signInAnonAndSync() async {
    try {
      await FirebaseAuth.instance.signInAnonymously();

      try {
        InstalledAppsHelper().syncInstalledApps();
      } catch (e) {
        //   print('Error syncing installed apps: $e');
      }

      await trackOpen();
    } catch (e) {
      // print('Firebase anonymous sign-in error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Welcome to Magic Wand'),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 18.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  RichText(
                    text: TextSpan(
                      text:
                          'In order to provide better services, Magic Wand will use your personal information. Please review and agree to the following before continuing: ',
                      style: BrandText.textBody,
                      children: const <TextSpan>[
                        TextSpan(
                          text: '<<Privacy Policy>>',
                          style: BrandText.sRed,
                        ),
                        TextSpan(
                          text: ' and ',
                          style: BrandText.textBody,
                        ),
                        TextSpan(
                          text: '<<User Agreement>> ',
                          style: BrandText.sRed,
                        ),
                        TextSpan(
                            style: BrandText.textBody,
                            text:
                                'If you choose not to agree, you will not be able to use our products and services. The app may collect your mobile device and behavior data (directly or via third parties) to support necessary business operations, evaluation, support, and personalized content. See the '),
                        TextSpan(
                          text: '<<Privacy Policy>> ',
                          style: BrandText.sRed,
                        ),
                        TextSpan(
                            style: BrandText.textBody,
                            text:
                                'for full details about how your information is collected, used, and shared.')
                      ],
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  const WelcomItem(
                    title: 'Bluetooth (Required)',
                    text:
                        'Used for sharing device data with the app to provide complete health services.',
                  ),
                  const WelcomItem(
                    title: 'Location (Required)',
                    text:
                        'Used for device scanning and connections when pairing or syncing devices.',
                  ),
                  const WelcomItem(
                    title: 'Photos & Camera (Optional)',
                    text:
                        'Used when you send images or change your profile picture.',
                  ),
                  const WelcomItem(
                    title: 'Microphone (Optional)',
                    text: 'Used for voice chat and audio features.',
                  ),
                  const WelcomItem(
                    title: 'Avatar & Nickname (Optional)',
                    text:
                        'Used for identifying you in chat and social features.',
                  ),
                  const Text(
                    'You may disable permissions in system settings, but some features may not work properly.',
                    style: BrandText.swTitle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8.0),
            Center(
              child: isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        setState(() => isLoading = true);
                        await onAgreePressed(context);
                        setState(() => isLoading = false);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 18.0, vertical: 4.0),
                        child: Text(
                          'Agree and Continue',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Disagree and Exit'),
            ),
          ],
        ),
      ),
    );
  }

  /// Triggered when user presses "Agree and Continue"
  Future<void> onAgreePressed(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isFirstLaunch', false);

      final allGranted = await requestStartPermissions(context);

      if (allGranted) {
        await startServiceIfNeeded();
      } else {
        //print('Permissions not granted, service will not start');
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } catch (e) {
      // print('Error in onAgreePressed: $e');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    }
  }

  /// Check network connectivity
  Future<bool> isConnected() async {
    try {
      return (await Connectivity().checkConnectivity())
          .any((element) => element != ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  /// Track device open and save device info
  Future<void> trackOpen() async {
    try {
      if (!(await isConnected())) {
        throw Exception("No internet connection");
      }
      final String? id = await DeviceInfoHelper.getUID();
      if (id != null) {
        await DeviceHelper.open(id);
        await DeviceHelper.getLocation(id);
      } else {
        await saveDeviceInfo();
        await trackOpen();
      }
    } catch (e) {
      //  print('Error in trackOpen: $e');
    }
  }

  Future<void> saveDeviceInfo() async {
    final result = await DeviceInfoHelper.saveUserId();
    if (result['done']) {
      try {
        await DeviceHelper.saveInfo(result['id']);
      } catch (e) {
        // print('Error saving device info: $e');
      }
    } else {
      await saveDeviceInfo();
    }
  }
}

class WelcomItem extends StatelessWidget {
  const WelcomItem({super.key, required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8.0,
              height: 8.0,
              decoration: const BoxDecoration(
                  color: BrandColor.kRed, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12.0),
            Text(title, style: BrandText.swTitle),
          ],
        ),
        Text(text, style: BrandText.bodyTitle),
        const SizedBox(height: 12.0),
      ],
    );
  }
}
