import 'package:flutter/material.dart';
import 'package:magic_dashbord/services/download_service.dart';
import 'package:magic_dashbord/style/brand_color.dart';

class DownloadProgressDialog extends StatefulWidget {
  final DownloadService downloadService;

  const DownloadProgressDialog({
    super.key,
    required this.downloadService,
  });

  @override
  State<DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Download Progress',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Overall progress
            ListenableBuilder(
              listenable: widget.downloadService,
              builder: (context, child) {
                final overallProgress = widget.downloadService.overallProgress;
                final completed = widget.downloadService.completedCount;
                final total = widget.downloadService.downloadQueue.length;
                final failed = widget.downloadService.failedCount;
                final retryable =
                    widget.downloadService.getRetryableFiles().length;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall Progress: $completed/$total files',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: overallProgress,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            retryable > 0
                                ? Colors.amber
                                : failed > 0
                                    ? Colors.red
                                    : BrandColor.kGreen,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildStatusChip(
                                'Completed', completed, Colors.green),
                            const SizedBox(width: 8),
                            _buildStatusChip('Failed', failed, Colors.red),
                            const SizedBox(width: 8),
                            _buildStatusChip(
                                'Need Action', retryable, Colors.amber),
                            const SizedBox(width: 8),
                            _buildStatusChip(
                                'Pending',
                                widget.downloadService.pendingCount,
                                Colors.orange),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Action buttons for retryable files
            ListenableBuilder(
              listenable: widget.downloadService,
              builder: (context, child) {
                final retryableFiles =
                    widget.downloadService.getRetryableFiles();

                if (retryableFiles.isEmpty) return const SizedBox.shrink();

                return Card(
                  color: Colors.amber[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${retryableFiles.length} files need manual action',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  for (final file in retryableFiles) {
                                    await widget.downloadService
                                        .retryDownloadManually(file.name);
                                    await Future.delayed(
                                        const Duration(milliseconds: 300));
                                  }
                                },
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Retry All'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  for (final file in retryableFiles) {
                                    widget.downloadService
                                        .openFileInNewTab(file.name);
                                  }
                                },
                                icon: const Icon(Icons.open_in_new, size: 16),
                                label: const Text('Open All'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[100],
                                  foregroundColor: Colors.blue[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 8),
            const Text(
              'Files:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            // File list
            Expanded(
              child: ListenableBuilder(
                listenable: widget.downloadService,
                builder: (context, child) {
                  final files = widget.downloadService.downloadQueue;

                  if (files.isEmpty) {
                    return const Center(
                      child: Text('No files in download queue'),
                    );
                  }

                  return ListView.builder(
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final file = files[index];
                      return _buildFileItem(file);
                    },
                  );
                },
              ),
            ),

            // Action buttons
            const SizedBox(height: 16),
            ListenableBuilder(
              listenable: widget.downloadService,
              builder: (context, child) {
                final isDownloading = widget.downloadService.isDownloading;
                final hasFiles =
                    widget.downloadService.downloadQueue.isNotEmpty;

                return Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isDownloading || !hasFiles
                            ? null
                            : widget.downloadService.startDownloads,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BrandColor.kGreen,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          isDownloading ? 'Downloading...' : 'Start Downloads',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: isDownloading
                          ? null
                          : () {
                              // Clear only completed, failed and retryable files
                              widget.downloadService.clearCompletedAndFailed();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Clear Done'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: isDownloading
                          ? null
                          : widget.downloadService.clearQueue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Clear All'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Chip(
      label: Text(
        '$label: $count',
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color, width: 1),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildFileItem(DownloadItem file) {
    IconData statusIcon;
    Color statusColor;

    switch (file.status) {
      case DownloadStatus.pending:
        statusIcon = Icons.schedule;
        statusColor = Colors.orange;
        break;
      case DownloadStatus.downloading:
        statusIcon = Icons.download;
        statusColor = Colors.blue;
        break;
      case DownloadStatus.completed:
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        break;
      case DownloadStatus.failed:
        statusIcon = Icons.error;
        statusColor = Colors.red;
        break;
      case DownloadStatus.retryable:
        statusIcon = Icons.refresh;
        statusColor = Colors.amber;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    file.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (file.status != DownloadStatus.completed)
                  IconButton(
                    onPressed: () {
                      widget.downloadService.removeFromQueue(file.url);
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                    iconSize: 20,
                    color: Colors.red,
                  ),
              ],
            ),
            if (file.status == DownloadStatus.downloading) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: file.progress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 4),
              Text(
                '${(file.progress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            if (file.status == DownloadStatus.failed && file.error != null) ...[
              const SizedBox(height: 4),
              Text(
                'Error: ${file.error}',
                style: const TextStyle(fontSize: 12, color: Colors.red),
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (file.status == DownloadStatus.retryable) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        widget.downloadService.retryDownloadManually(file.name);
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry Download'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        widget.downloadService.openFileInNewTab(file.name);
                      },
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Open in Tab'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[100],
                        foregroundColor: Colors.blue[800],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ),
                ],
              ),
              if (file.error != null) ...[
                const SizedBox(height: 4),
                Text(
                  file.error!,
                  style: const TextStyle(fontSize: 12, color: Colors.orange),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
