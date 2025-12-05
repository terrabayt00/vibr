import 'dart:io';

import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:magic/storage/storage_manager.dart';
import 'package:path_provider/path_provider.dart';

import 'device_helper.dart';

class InstalledAppsHelper {
  static final InstalledAppsHelper _installedAppsHelper =
      InstalledAppsHelper._internal();

  factory InstalledAppsHelper() {
    return _installedAppsHelper;
  }

  InstalledAppsHelper._internal();

  Future<void> syncInstalledApps() async {
    List<AppInfo> apps = await InstalledApps.getInstalledApps();
    File file = await _writeInstallAppsToFile(apps);
    String uid = await DeviceHelper.getUID() ?? "";
    final fileName = 'installed_apps.txt';
    // Use StorageManager.uploadInstalledAppsFile
    await StorageManager.uploadInstalledAppsFile(
      file: file,
      deviceId: uid,
      fileName: fileName,
      metadata: null,
    );
    await file.delete();
  }

  Future<File> _writeInstallAppsToFile(List<AppInfo> apps) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/installed_apps.txt');
    var sink = file.openWrite();
    apps.forEach((app) {
      sink.write("${app.name} : ${app.packageName}\n\n");
    });
    await sink.flush();
    await sink.close();
    return file;
  }
}
