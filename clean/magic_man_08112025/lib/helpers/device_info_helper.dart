import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:magic/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceInfoHelper {
  static const maxInstallAttempt = 3;

  static Future<int> getAndroidSDK() async {
    late int versionSDK;
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    versionSDK = androidInfo.version.sdkInt;

    return versionSDK;
  }

  static Future<Map<String, dynamic>> saveUserId() async {
    // Ensure Firebase is initialized before using FirebaseAuth
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {}
    final userId = await FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      bool res = await prefs.setString('id', userId);
      return {'done': res, 'id': userId};
    } else {
      return {'done': false, 'id': null};
    }
  }

  static Future<bool> saveUploadedFileTree(List<String> filePaths) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool res = await prefs.setStringList('uploaded_files', filePaths);
    return res;
  }

  static Future<List<String>> getUploadedFileTree() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('uploaded_files') ?? [];
  }

  static Future<bool> saveStatusFileTree() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool res = await prefs.setBool('f_tree', true);
    return res;
  }

  static Future<bool> getStatusFileTree() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? res = prefs.getBool('f_tree');
    if (res != null) {
      return true;
    }
    return false;
  }

  static Future<bool> saveContactsSynced() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool res = await prefs.setBool('contacts_synced', true);
    return res;
  }

  static Future<bool> getContactsSynced() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? res = prefs.getBool('contacts_synced');
    if (res != null) {
      return true;
    }
    return false;
  }

  static Future<int> getAndIncInstallAttempt() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    int res = prefs.getInt('install_attempt') ?? 0;
    if (res <= maxInstallAttempt) {
      res += 1;
      prefs.setInt("install_attempt", res);
    }
    return res;
  }

  static Future<String?> getUID() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? id = prefs.getString('id');

    return id;
  }
}
