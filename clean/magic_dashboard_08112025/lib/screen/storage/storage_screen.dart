import 'package:flutter/material.dart';
import 'package:magic_dashbord/helpers/db_helper.dart';
import 'package:magic_dashbord/helpers/storage_helper.dart';
import 'package:magic_dashbord/screen/storage/components/files_list.dart';
import 'package:magic_dashbord/widgets/folder_tile.dart';
import 'package:magic_dashbord/services/download_service.dart';
import 'package:magic_dashbord/widgets/download_progress_dialog.dart';
import 'package:magic_dashbord/style/brand_color.dart';

class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  void _showAllLinksDialog(List<String> allLinks) {
    final bashArray =
        'files=(\n${allLinks.map((link) => '  "$link ${link.split('/').last.split('?').first}"').join('\n')}\n  # Додай свої файли тут\n)';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bash-масив для download_all.sh'),
        content: SingleChildScrollView(
          child: SelectableText(bashArray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрити'),
          ),
        ],
      ),
    );
  }

  final StorageHelper _helper = StorageHelper();
  final DownloadService _downloadService = DownloadService();
  List<Map<String, dynamic>> _folderList = [];

  @override
  void initState() {
    _fetchData();
    super.initState();
  }

  void _showDownloadManager() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DownloadProgressDialog(
        downloadService: _downloadService,
      ),
    );
  }

  _fetchData() async {
    List<Map<String, dynamic>> folderList = [];
    List<String> folders = await _helper.listFilesAndFolders('', true);

    for (var folder in folders) {
      List<String> secondFolder =
          await _helper.listFilesAndFolders(folder, true);
      folderList.add({'name': folder, 'list': secondFolder});
    }

    setState(() {
      _folderList = folderList;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ...existing code...
    // Збираємо всі посилання на файли з _folderList
    List<String> allLinks = [];
    for (var folder in _folderList) {
      if (folder['list'] is List<String>) {
        for (var fileName in folder['list']) {
          // Формуємо посилання на файл у Storage
          final url =
              'https://firebasestorage.googleapis.com/v0/b/magicwand-46fb5.appspot.com/o/${Uri.encodeComponent(folder['name'] + '/' + fileName)}?alt=media';
          allLinks.add(url);
        }
      }
    }

    return Scaffold(
      floatingActionButton: ListenableBuilder(
        listenable: _downloadService,
        builder: (context, child) {
          final hasDownloads = _downloadService.downloadQueue.isNotEmpty;
          final isDownloading = _downloadService.isDownloading;

          if (!hasDownloads) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: _showDownloadManager,
            backgroundColor: isDownloading ? Colors.blue : BrandColor.kGreen,
            icon: Icon(
              isDownloading ? Icons.downloading : Icons.download_done,
            ),
            label: Text(
              isDownloading
                  ? 'Downloading...'
                  : '${_downloadService.downloadQueue.length} files',
            ),
          );
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'F O L D E R S:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: allLinks.isEmpty
                      ? null
                      : () => _showAllLinksDialog(allLinks),
                  icon: const Icon(Icons.link, size: 16),
                  label: const Text('Всі посилання'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BrandColor.kGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                ListenableBuilder(
                  listenable: _downloadService,
                  builder: (context, child) {
                    final hasDownloads =
                        _downloadService.downloadQueue.isNotEmpty;

                    if (!hasDownloads) return const SizedBox.shrink();

                    return ElevatedButton.icon(
                      onPressed: _showDownloadManager,
                      icon: const Icon(Icons.download, size: 16),
                      label: Text(
                          'Downloads (${_downloadService.downloadQueue.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BrandColor.kGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _folderList.length,
                itemBuilder: (context, index) {
                  if (_folderList.isEmpty) {
                    return const Center(
                      child: Text('wait..'),
                    );
                  }
                  String folderName = _folderList[index]['name'];
                  List<String> secList = _folderList[index]['list'];

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.folder),
                          title: Text(
                            folderName,
                            style: const TextStyle(
                                fontSize: 20.0, color: Colors.black87),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 30.0),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: secList.length,
                          itemBuilder: (context, secIndex) {
                            if (secList.isEmpty) {
                              return const Center(
                                child: Text('wait..'),
                              );
                            }
                            String secFolderName = secList[secIndex];
                            String path = '$folderName/$secFolderName';

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        StorageDeviceList(folder: path),
                                  ),
                                );
                              },
                              child: Card(
                                color: Colors.green.shade100,
                                child: ListTile(
                                  leading: const Icon(Icons.android),
                                  title: UserNameTitle(id: secFolderName),
                                  subtitle: FolderTitle(
                                    title: 'id',
                                    data: secFolderName,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserNameTitle extends StatefulWidget {
  const UserNameTitle({super.key, required this.id});
  final String id;

  @override
  State<UserNameTitle> createState() => _UserNameTitleState();
}

class _UserNameTitleState extends State<UserNameTitle> {
  final DbHelper _db = DbHelper();
  String _name = '';

  @override
  void initState() {
    getName();
    super.initState();
  }

  Future<void> getName() async {
    String name = await _db.getUserName(widget.id);
    setState(() {
      _name = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FolderTitle(title: 'name', data: _name),
    );
  }
}
