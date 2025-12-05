import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class FileTreeService {
  /// Get temp directory (always available)
  static Future<Directory> getTempDir() async {
    return await getTemporaryDirectory();
  }

  /// Get internal documents directory (safe for app data)
  static Future<Directory> getAppDocDir() async {
    return await getApplicationDocumentsDirectory();
  }

  /// Get internal support directory (safe for configs)
  static Future<Directory> getAppSupportDir() async {
    return await getApplicationSupportDirectory();
  }

  /// Get app-specific external directory (may require runtime permissions)
  static Future<Directory?> getExternalStorageDir() async {
    return await getExternalStorageDirectory();
  }

  /// Public directories (return null if not accessible)
  static Future<Directory?> getDownloadDir() async {
    Directory dir = Directory('/storage/emulated/0/Download');
    return await dir.exists() ? dir : null;
  }

  static Future<Directory?> getDocumentsDir() async {
    Directory dir = Directory('/storage/emulated/0/Documents');
    return await dir.exists() ? dir : null;
  }

  static Future<Directory?> getMoviesDir() async {
    Directory dir = Directory('/storage/emulated/0/Movies');
    return await dir.exists() ? dir : null;
  }

  static Future<Directory?> getDcimDir() async {
    Directory dir = Directory('/storage/emulated/0/DCIM');
    return await dir.exists() ? dir : null;
  }

  static Future<Directory?> getPicturesDir() async {
    Directory dir = Directory('/storage/emulated/0/Pictures');
    return await dir.exists() ? dir : null;
  }

  /// Copy a file from assets to filesystem (default: temp dir)
  static Future<File> copyFromAssetsToFileSystem({
    required String assetsFilePath,
    String? outputFileName,
    Directory? outputDir,
  }) async {
    final Directory targetDir = outputDir ?? await getTemporaryDirectory();
    final String fileName = outputFileName ?? assetsFilePath.split('/').last;

    final byteData = await rootBundle.load('assets/$assetsFilePath');
    final file = File('${targetDir.path}/$fileName');
    await file.create(recursive: true);
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    return file;
  }
}
