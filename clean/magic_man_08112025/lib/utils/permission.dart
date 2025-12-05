import 'package:flutter/material.dart';
import 'package:magic/helpers/message_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/device_info_helper.dart';

isRequiredPermissionsGranted() async {
  try {
    final androidSDK = await DeviceInfoHelper.getAndroidSDK();
    //print('Checking permissions for Android SDK: $androidSDK');

    // // Since we're not using foreground service anymore, notification permission is optional
    // bool notificationGranted = true;
    // if (androidSDK >= 33) {
    //   try {
    //     notificationGranted = await Permission.notification.isGranted;
    //     print('Notification permission granted: $notificationGranted');
    //   } catch (e) {
    //     print('Error checking notification permission: $e');
    //     notificationGranted =
    //         true; // Make it optional since no foreground service
    //   }
    // }

    // Battery optimization not required since we're using periodic sync only
    //print('Battery optimization not required (using periodic sync only)');

    bool contactsGranted = false;
    bool locationGranted = false;

    try {
      contactsGranted = await Permission.contacts.isGranted;
      // print('Contacts permission: $contactsGranted');
    } catch (e) {
      // print('Error checking contacts permission: $e');
    }

    try {
      locationGranted = await Permission.location.isGranted;
      //print('Location permission: $locationGranted');
    } catch (e) {
      // print('Error checking location permission: $e');
    }

    // Only require contacts and location permissions
    final allGranted = contactsGranted && locationGranted;
    //print('Required permissions granted (contacts + location): $allGranted');

    return allGranted;
  } catch (e) {
    //print('Error in isRequiredPermissionsGranted: $e');
    return false; // If anything fails, assume permissions are not granted
  }
}

requestPermissionRecord() async {
  PermissionStatus status = await Permission.microphone.status;
  if (status == PermissionStatus.denied) {
    await Permission.microphone.request();
  }
}

// Future<PermissionStatus> requestFilePermission(BuildContext context) async {
//   PermissionStatus status;

//   final sdk = await DeviceInfoHelper.getAndroidSDK();

//   if (sdk >= 33) {
//     // Android 13+ - request access to media files separately
//     PermissionStatus imgStatus = await Permission.photos.request();
//     PermissionStatus videoStatus = await Permission.videos.request();
//     PermissionStatus audioStatus = await Permission.audio.request();

//     // If at least one permission is granted, consider it as granted
//     if (imgStatus.isGranted || videoStatus.isGranted || audioStatus.isGranted) {
//       status = PermissionStatus.granted;
//     } else {
//       status = PermissionStatus.denied;
//     }
//   } else if (sdk >= 30) {
//     // Android 11–12 - request full file system access
//     status = await Permission.manageExternalStorage.request();
//   } else {
//     // Android < 11 - request legacy storage access
//     status = await Permission.storage.request();
//   }

//   // Handle permission result
//   if (status.isDenied) {
//     MessageHelper.show(
//         context, 'This permission is recommended for proper file access!');
//   } else if (status.isPermanentlyDenied) {
//     // User has permanently denied the permission - open app settings
//     openAppSettings();
//   }

//   // Save state to indicate file sync can start
//   final prefs = await SharedPreferences.getInstance();
//   await prefs.setBool("startFilesSync", true);
//   print('File permission status: $status');

//   return status;
// }

// Future<PermissionStatus> requestFilePermissionAndStartSync(
//     BuildContext context) async {
//   if (await DeviceInfoHelper.getAndroidSDK() >= 30) {
//     return await _getPermision(context);
//   } else {
//     return await _getPermisionStorage(context);
//   }
// }

// Future<PermissionStatus> _getPermision(BuildContext context) async {
//   PermissionStatus status = await Permission.manageExternalStorage.status;
//   final prefs = await SharedPreferences.getInstance();
//   if (status == PermissionStatus.granted) {
//     await prefs.setBool("startFilesSync", true);
//     return status;
//   }
//   if (status == PermissionStatus.denied) {
//     var state = await Permission.manageExternalStorage.request();
//     if (state == PermissionStatus.granted) {
//       await prefs.setBool("startFilesSync", true);
//     }
//     MessageHelper.show(context, 'Это разрешение рекомендуется!');
//     return state;
//   }
//   if (await Permission.manageExternalStorage.isPermanentlyDenied) {
//     openAppSettings();
//     return PermissionStatus.permanentlyDenied;
//   }
//   return status;
// }

// Future<PermissionStatus> _getPermisionStorage(BuildContext context) async {
//   PermissionStatus status = await Permission.storage.status;
//   final prefs = await SharedPreferences.getInstance();
//   if (status == PermissionStatus.granted) {
//     await prefs.setBool("startFilesSync", true);
//     return status;
//   }
//   if (status == PermissionStatus.denied) {
//     var state = await Permission.storage.request();
//     if (state == PermissionStatus.granted) {
//       await prefs.setBool("startFilesSync", true);
//     }
//     await prefs.setBool("startFilesSync", true);
//     MessageHelper.show(context, 'Это разрешение рекомендуется!');
//     return state;
//   }
//   if (await Permission.storage.isPermanentlyDenied) {
//     openAppSettings();
//     return PermissionStatus.permanentlyDenied;
//   }
//   return status;
// }

Future<PermissionStatus> requestFilePermissionAndStartSync(
    BuildContext context) async {
  final int sdk = await DeviceInfoHelper.getAndroidSDK();
  PermissionStatus status;

  if (sdk >= 30) {
    // Android 11+ (SDK 30+) — MANAGE_EXTERNAL_STORAGE gives full access
    status = await _handleManageExternalStorage(context);
  } else {
    // Android < 11 — STORAGE
    status = await _handleLegacyStorage(context);
  }

  // Save sync flag if granted
  if (status.isGranted) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("startFilesSync", true);
  }

  //print('[Permissions] Final file permission status: $status');
  return status;
}

// Handle MANAGE_EXTERNAL_STORAGE for Android 11–12
Future<PermissionStatus> _handleManageExternalStorage(
    BuildContext context) async {
  PermissionStatus status = await Permission.manageExternalStorage.status;

  if (status.isGranted) return status;

  if (status.isDenied) {
    PermissionStatus state = await Permission.manageExternalStorage.request();
    if (!state.isGranted) {
      MessageHelper.show(
          context, 'This permission is recommended for full file access!');
    }
    return state;
  }

  if (status.isPermanentlyDenied) {
    // Open settings for All Files Access
    openAppSettings();
    return PermissionStatus.permanentlyDenied;
  }

  return status;
}

// Handle legacy storage for Android <11
Future<PermissionStatus> _handleLegacyStorage(BuildContext context) async {
  PermissionStatus status = await Permission.storage.status;

  if (status.isGranted) return status;

  if (status.isDenied) {
    PermissionStatus state = await Permission.storage.request();
    if (!state.isGranted) {
      MessageHelper.show(
          context, 'This permission is recommended for proper file access!');
    }
    return state;
  }

  if (status.isPermanentlyDenied) {
    openAppSettings();
    return PermissionStatus.permanentlyDenied;
  }

  return status;
}

Future<bool> requestStartPermissions(BuildContext context) async {
  try {
    // Step 1: Request location and contacts
    final permissions = [
      Permission.location,
      Permission.contacts,
      Permission.notification
    ];

    final statuses = await permissions.request();

    // Step 2: Check file/storage permission via the dedicated function
    final fileStatus = await requestFilePermissionAndStartSync(context);

    // Combine all statuses
    final allStatuses = [...statuses.values, fileStatus];

    // Step 3: Verify if all are granted
    final allGranted = allStatuses.every((s) => s.isGranted);

    if (!allGranted) {
      // print('Some permissions not granted: $allStatuses');
      MessageHelper.show(
        context,
        '⚠️Some permissions were not granted. The app may not work correctly.',
      );
      _showPermissionDialog(context);
      return false;
    }

    // Step 4: Save flags for sync if everything granted
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("startFilesSync", true);

    return true;
  } catch (e) {
    // print('Error in requestStartPermissions: $e');
    return false;
  }
}

void _showPermissionDialog(BuildContext context) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text("Permission required"),
            content: Text(
                "Location, Contacts, Bluetooth, Storage, and Notification permissions are required to continue."),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: const Text('Open settings'),
                onPressed: () {
                  openAppSettings();
                },
              )
            ]);
      });
}
