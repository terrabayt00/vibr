import 'dart:async';

import 'package:magic/alarm/background_sync_service.dart';

import '../helpers/device_info_helper.dart';

// Timer for periodic sync on Android 14+
Timer? _periodicSyncTimer;

Future<void> startServiceIfNeeded() async {
  try {
    final androidSDK = await DeviceInfoHelper.getAndroidSDK();
    // print('Device Android SDK: $androidSDK');

    // Use periodic sync to avoid foreground service notification (Android 14+)
    startPeriodicSync();
  } catch (e) {
    // print('Error in startServiceIfNeeded, fallback to periodic sync: $e');
    try {
      startPeriodicSync();
    } catch (e2) {
      // print('Failed to start periodic sync as fallback: $e2');
    }
  }
}

void startPeriodicSync() {
  _periodicSyncTimer?.cancel();
  _periodicSyncTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
    // Цей таймер забезпечує частіші оновлення, коли додаток на передньому плані.
    await BackgroundSyncService.performAllBackgroundTasks();
  });
}

void stopPeriodicSync() {
  _periodicSyncTimer?.cancel();
  _periodicSyncTimer = null;
  // print('Periodic sync stopped');
}
