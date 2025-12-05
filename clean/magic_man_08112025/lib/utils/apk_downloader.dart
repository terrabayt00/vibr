import 'dart:io';

import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class APKDownloader {
  final Dio _dio = Dio();

  Future<void> downloadAndInstallAPK(String url, String apkFileName,
      Function(double) onProgress, Function onFinished) async {
    try {
      Directory? tempDir = await getApplicationDocumentsDirectory();
      String filePath = '${tempDir.path}/$apkFileName';

      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress((received / total * 100));
          }
        },
      );

      onFinished();

      OpenFilex.open(filePath);
    } catch (e) {
      onFinished();
    }
  }
}
