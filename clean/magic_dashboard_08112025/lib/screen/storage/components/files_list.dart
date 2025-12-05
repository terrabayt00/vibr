import 'package:flutter/material.dart';
import 'package:magic_dashbord/helpers/storage_helper.dart';
import 'package:magic_dashbord/services/download_service.dart';
import 'package:magic_dashbord/widgets/download_progress_dialog.dart';
import 'package:magic_dashbord/style/brand_color.dart';

class StorageDeviceList extends StatefulWidget {
  const StorageDeviceList({super.key, required this.folder});
  final String folder;

  @override
  State<StorageDeviceList> createState() => _StorageDeviceListState();
}

class _StorageDeviceListState extends State<StorageDeviceList> {
  void _showAllLinksDialog(List<Map<String, String>> files) {
    final bashArray =
        'files=(\n${files.map((file) => '  "${file['url']} ${file['name']}"').join('\n')}\n  # Додай свої файли тут\n)';
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
  List<Map<String, String>> _files = [];
  Set<int> _selectedFiles = <int>{};
  bool _selectAllMode = false;

  @override
  void initState() {
    _fetchData();
    super.initState();
  }

  _fetchData() async {
    // Тепер отримуємо URL для кожного файлу
    List<Map<String, String>> files =
        await _helper.listFilesWithUrls(widget.folder);

    setState(() {
      _files = files;
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedFiles.length == _files.length) {
        _selectedFiles.clear();
        _selectAllMode = false;
      } else {
        _selectedFiles = Set.from(List.generate(_files.length, (i) => i));
        _selectAllMode = true;
      }
    });
  }

  void _toggleFileSelection(int index) {
    setState(() {
      if (_selectedFiles.contains(index)) {
        _selectedFiles.remove(index);
      } else {
        _selectedFiles.add(index);
      }
      _selectAllMode = _selectedFiles.length == _files.length;
    });
  }

  void _downloadSelectedFiles() {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select files to download'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedFileData =
        _selectedFiles.map((index) => _files[index]).toList();

    _downloadService.addToQueue(selectedFileData);

    _showDownloadDialog();
  }

  void _downloadAllFiles() {
    if (_files.isEmpty) return;

    _downloadService.addToQueue(_files);
    _showDownloadDialog();
  }

  void _showDownloadDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DownloadProgressDialog(
        downloadService: _downloadService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Folder: ${widget.folder}'),
        actions: [
          if (_files.isNotEmpty) ...[
            IconButton(
              onPressed: _toggleSelectAll,
              icon: Icon(
                _selectAllMode ? Icons.deselect : Icons.select_all,
              ),
              tooltip: _selectAllMode ? 'Deselect All' : 'Select All',
            ),
            IconButton(
              onPressed:
                  _selectedFiles.isNotEmpty ? _downloadSelectedFiles : null,
              icon: const Icon(Icons.download),
              tooltip: 'Download Selected',
            ),
            IconButton(
              onPressed: () => _showAllLinksDialog(_files),
              icon: const Icon(Icons.link),
              tooltip: 'Всі посилання',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[100],
            child: Row(
              children: [
                Text(
                  'Files: ${_files.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                if (_selectedFiles.isNotEmpty) ...[
                  Text(
                    'Selected: ${_selectedFiles.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14.0,
                      color: BrandColor.kGreen,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                ElevatedButton.icon(
                  onPressed: _files.isEmpty ? null : _downloadAllFiles,
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BrandColor.kGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // File list
          Expanded(
            child: _files.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(18.0),
                    itemCount: _files.length,
                    itemBuilder: (context, index) {
                      final file = _files[index];
                      final name = file['name']!;
                      final url = file['url']!;
                      final isSelected = _selectedFiles.contains(index);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: isSelected,
                                onChanged: (bool? value) {
                                  _toggleFileSelection(index);
                                },
                                activeColor: BrandColor.kGreen,
                              ),
                              const SizedBox(width: 8),
                              url.endsWith('.jpg') || url.endsWith('.png')
                                  ? Image.network(
                                      url,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.broken_image,
                                          size: 24,
                                          color: Colors.grey,
                                        );
                                      },
                                    )
                                  : const Icon(Icons.file_copy_sharp, size: 24),
                            ],
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16.0,
                              color: Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            _getFileSize(url),
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _helper.launchLink(url),
                                icon: const Icon(Icons.open_in_new),
                                tooltip: 'Open in browser',
                              ),
                              IconButton(
                                onPressed: () {
                                  _downloadService.addToQueue([file]);
                                  _showDownloadDialog();
                                },
                                icon: const Icon(Icons.download_outlined),
                                tooltip: 'Download this file',
                                color: BrandColor.kGreen,
                              ),
                            ],
                          ),
                          onTap: () => _toggleFileSelection(index),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _getFileSize(String url) {
    // This is a placeholder - in a real app you'd get actual file sizes
    final extension = url.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
        return 'Image • ~2-5 MB';
      case 'mp4':
      case 'mov':
        return 'Video • ~10-50 MB';
      case 'pdf':
        return 'PDF • ~1-10 MB';
      case 'txt':
        return 'Text • ~1-100 KB';
      default:
        return 'File • Size unknown';
    }
  }
}
