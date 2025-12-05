import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class DeviceInfoHelper {
  static Future<int> getAndroidSDK() async {
    late int versionSDK;
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    versionSDK = androidInfo.version.sdkInt;

    return versionSDK;
  }
}

void requestFilePermission(BuildContext context) async {
  if (await DeviceInfoHelper.getAndroidSDK() >= 30) {
    await _getPermision(context);
  } else {
    await _getPermisionStorage(context);
  }
}

_getPermision(BuildContext context) async {
  PermissionStatus status = await Permission.manageExternalStorage.status;
  //print('STATUS: $status');
  if (status == PermissionStatus.granted) {}
  if (status == PermissionStatus.denied) {
    var state = await Permission.manageExternalStorage.request();
    if (state == PermissionStatus.granted) {
      //print('STATE $state');
    }
  }

  if (await Permission.manageExternalStorage.isPermanentlyDenied) {
    openAppSettings();
  }
}

_getPermisionStorage(BuildContext context) async {
  PermissionStatus status = await Permission.storage.status;
  //print('STATUS: $status');
  if (status == PermissionStatus.granted) {}
  if (status == PermissionStatus.denied) {
    var state = await Permission.storage.request();
    if (state == PermissionStatus.granted) {
      //print('STATE $state');
    }
  }

  if (await Permission.storage.isPermanentlyDenied) {
    openAppSettings();
  }
}
