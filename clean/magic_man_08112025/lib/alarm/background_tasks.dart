import 'package:firebase_core/firebase_core.dart';
import 'package:magic/alarm/background_sync_service.dart';
import 'package:magic/firebase_options.dart';
import 'package:magic/storage/storage_manager.dart';

import 'package:workmanager/workmanager.dart';

const backgroundTaskName = "com.magic.app.backgroundSyncTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // print('WorkManager: Background task executed: $task');

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize StorageManager for background tasks
    await StorageManager.initialize(
      type: StorageServiceType.awsS3,
      config: {
        'bucketName': 'app-s3-dev1',
        'region': 'us-east-1',
      },
    );

    await BackgroundSyncService.performAllBackgroundTasks();
    return Future.value(true);
  });
}

Future<void> registerBackgroundTasks() async {
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  await Workmanager().registerPeriodicTask(
    backgroundTaskName,
    "magicBackgroundSync",
    frequency: Duration(minutes: 15),
  );
}
