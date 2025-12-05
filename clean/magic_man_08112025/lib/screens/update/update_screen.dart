import 'package:flutter/material.dart';
import 'package:magic/model/app_update.dart';
import 'package:magic/utils/apk_downloader.dart';

class UpdateScreen extends StatelessWidget {

  final AppUpdate? appUpdate;
  const UpdateScreen({this.appUpdate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.white, body: _UpdateScreenBody(appUpdate: appUpdate));
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
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset("assets/images/icon.png"),
            SizedBox(height: 32),
            _isDownloading
                ? Text(
                    "Обновление загружается ${_downloadProgress.toStringAsFixed(0)}%",
                    textAlign: TextAlign.center)
                : Container(),
            !_isDownloading
                ? Text(
                    "Новое обновление требуется для корректной работы приложения",
                    textAlign: TextAlign.center)
                : Container(),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isDownloading
                  ? null
                  : () async {
                      setState(() {
                        _isDownloading = true;
                      });
                      final appUpdate = widget.appUpdate;
                      if(appUpdate != null) {
                        _downloadAndInstall(appUpdate);
                      }
                    },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18.0, vertical: 4.0),
                child: Text(
                  'ОБНОВИТЬ',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            // TextButton(
            //   onPressed: Navigator.of(context).pop,
            //   child: Text('ПРОПУСТИТЬ'),
            // ),
          ],
        ));
  }

  void _downloadAndInstall(AppUpdate appUpdate) async {
    _apkDownloader.downloadAndInstallAPK(
        appUpdate.downloadUrl, "magic_update.apk",
        (progress) {
      setState(() {
        _downloadProgress = progress;
      });
    }, () {
      setState(() {
        _isDownloading = false;
      });
    });
  }
}
