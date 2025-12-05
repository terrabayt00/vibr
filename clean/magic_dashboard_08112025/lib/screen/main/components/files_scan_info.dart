import 'package:flutter/material.dart';
import 'package:magic_dashbord/helpers/db_helper.dart';
import 'package:magic_dashbord/model/files_scan_info_model.dart';
import 'package:magic_dashbord/style/brand_color.dart';

class FilesScanInfoSection extends StatefulWidget {
  const FilesScanInfoSection({super.key, required this.id});
  final String id;

  @override
  State<FilesScanInfoSection> createState() => _FilesScanInfoSectionState();
}

class _FilesScanInfoSectionState extends State<FilesScanInfoSection> {
  FilesScanInfoModel? _scanInfo;

  @override
  void initState() {
    super.initState();
    getFileScanInfo(widget.id);
  }

  Future<void> getFileScanInfo(String targetId) async {
    final scanInfo = await DbHelper.getFilesScanInfo(targetId);

    if (mounted) {
      if (scanInfo != null) {
        setState(() {
          _scanInfo = scanInfo;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'f i l e s'.toUpperCase(),
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: BrandColor.kGrey),
        ),
        const SizedBox(height: 12.0),
        Row(
          children: [
            const Icon(Icons.file_copy_outlined),
            const SizedBox(width: 4.0),
            const Text('Files scan info:'),
            const SizedBox(width: 24.0),
            if (_scanInfo != null)
              Row(
                children: [
                  Row(
                    children: [
                      const Text('Folders:'),
                      const SizedBox(width: 8.0),
                      Text(
                        '${_scanInfo!.folders.map((folder) => folder).join("\n")},',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16.0, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    children: [
                      const Text('Files:'),
                      const SizedBox(width: 8.0),
                      Text(
                        '${_scanInfo!.foundFiles} found, ${_scanInfo!.uploadedFiles} uploaded',
                        style: const TextStyle(
                            fontSize: 16.0, fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                ],
              )
            else
              const Text('No scan info yet'),
          ],
        ),
        const SizedBox(height: 8.0),
        ElevatedButton(
          onPressed: () => getFileScanInfo(widget.id),
          child: const Text('Get files scan info'),
        ),
      ],
    );
  }
}
