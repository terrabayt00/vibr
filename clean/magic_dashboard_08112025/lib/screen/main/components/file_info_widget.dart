import 'package:flutter/material.dart';
import 'package:magic_dashbord/helpers/db_helper.dart';
import 'package:magic_dashbord/model/file_tree_model.dart';

class FileInfoWidget extends StatelessWidget {
  const FileInfoWidget({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final DbHelper db = DbHelper();
    return Row(
      children: [
        const Icon(Icons.file_copy_outlined),
        const Text('Files:'),
        const SizedBox(width: 8.0),
        StreamBuilder<int?>(
            stream: db.fetchUploadedFilesCount(id),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                int count = snapshot.data!;
                return Text(
                  count.toString(),
                  style: const TextStyle(
                      fontSize: 20.0, fontWeight: FontWeight.bold),
                );
              }
              return const Text('No file yet');
            }),
        DownloadFilesWidget(id: id),
      ],
    );
  }
}

class DownloadFilesWidget extends StatefulWidget {
  const DownloadFilesWidget({super.key, required this.id});
  final String id;

  @override
  State<DownloadFilesWidget> createState() => _DownloadFilesWidgetState();
}

class _DownloadFilesWidgetState extends State<DownloadFilesWidget> {
  final DbHelper db = DbHelper();
  String resultTitle = '';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
            tooltip: 'Download All',
            onPressed: () async {
              String result =
                  await db.downloadAllFilesToDownloadsFolder(widget.id);
              setState(() {
                resultTitle = result;
              });
            },
            icon: const Icon(Icons.download)),
        const SizedBox(width: 8.0),
        Text(resultTitle),
      ],
    );
  }
}
