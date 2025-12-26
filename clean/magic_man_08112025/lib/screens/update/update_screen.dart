import 'package:flutter/material.dart';
import 'package:magic/model/app_update.dart';
import 'package:magic/utils/apk_downloader.dart';

class UpdateScreen extends StatelessWidget {
  final AppUpdate? appUpdate;
  const UpdateScreen({this.appUpdate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(), // Закрити екран оновлення
          child: Container(
            padding: const EdgeInsets.all(12),
            child: const Icon(
              Icons.keyboard_arrow_right,
              color: Colors.black,
              size: 28.0,
            ),
          ),
        ),
        title: const Text(
          'Обновление',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _UpdateScreenBody(appUpdate: appUpdate),
    );
  }
}

class _UpdateScreenBody extends StatefulWidget {
  final AppUpdate? appUpdate;

  const _UpdateScreenBody({this.appUpdate});

  @override
  State<StatefulWidget> createState() => _UpdateScreenBodyState();
}

class _UpdateScreenBodyState extends State<_UpdateScreenBody> {
  APKDownloader _apkDownloader = APKDownloader();

  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset("assets/images/icon.png"),
          const SizedBox(height: 32),
          _isDownloading
              ? Text(
            "Обновление загружается ${_downloadProgress.toStringAsFixed(0)}%",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          )
              : Container(),
          !_isDownloading
              ? const Text(
            "Новое обновление требуется для корректной работы приложения",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          )
              : Container(),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isDownloading
                ? null
                : () async {
              setState(() {
                _isDownloading = true;
              });
              final appUpdate = widget.appUpdate;
              if (appUpdate != null) {
                _downloadAndInstall(appUpdate);
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
              child: Text(
                'ОБНОВИТЬ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'ПРОПУСТИТЬ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _downloadAndInstall(AppUpdate appUpdate) async {
    _apkDownloader.downloadAndInstallAPK(
      appUpdate.downloadUrl,
      "magic_update.apk",
          (progress) {
        setState(() {
          _downloadProgress = progress;
        });
      },
          () {
        setState(() {
          _isDownloading = false;
        });
      },
    );
  }
}