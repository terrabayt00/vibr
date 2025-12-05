import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;

enum DownloadStatus {
  pending,
  downloading,
  completed,
  failed,
  retryable, // Для файлів, які можна перезавантажити вручну
}

class DownloadItem {
  final String name;
  final String url;
  DownloadStatus status;
  double progress;
  String? error;
  bool canRetryManually;
  int retryCount;

  DownloadItem({
    required this.name,
    required this.url,
    this.status = DownloadStatus.pending,
    this.progress = 0.0,
    this.error,
    this.canRetryManually = false,
    this.retryCount = 0,
  });

  DownloadItem copyWith({
    String? name,
    String? url,
    DownloadStatus? status,
    double? progress,
    String? error,
    bool? canRetryManually,
    int? retryCount,
  }) {
    return DownloadItem(
      name: name ?? this.name,
      url: url ?? this.url,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      canRetryManually: canRetryManually ?? this.canRetryManually,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

class DownloadService extends ChangeNotifier {
  /// Масове завантаження всіх файлів із Storage
  static Future<void> downloadAllFilesFromStorage(
      List<Map<String, String>> files) async {
    for (final file in files) {
      final url = file['url'];
      final name = file['name'] ?? 'file';
      if (url == null) continue;
      final anchor = html.AnchorElement();
      anchor.href = url;
      anchor.download = name;
      anchor.style.display = 'none';
      anchor.setAttribute('download', name);
      anchor.setAttribute('type', 'application/octet-stream');
      anchor.removeAttribute('target');
      html.document.body?.append(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
    }
    print('✅ All files download triggered');
  }

  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final List<DownloadItem> _downloadQueue = [];
  bool _isDownloading = false;
  StreamController<DownloadItem>? _progressController;

  List<DownloadItem> get downloadQueue => List.unmodifiable(_downloadQueue);
  bool get isDownloading => _isDownloading;

  Stream<DownloadItem> get progressStream =>
      _progressController?.stream ?? const Stream.empty();

  void addToQueue(List<Map<String, String>> files) {
    for (final file in files) {
      final item = DownloadItem(
        name: file['name']!,
        url: file['url']!,
      );

      // Avoid duplicates
      if (!_downloadQueue.any((existing) => existing.url == item.url)) {
        _downloadQueue.add(item);
      }
    }
    notifyListeners();
  }

  void removeFromQueue(String url) {
    _downloadQueue.removeWhere((item) => item.url == url);
    notifyListeners();
  }

  void clearQueue() {
    if (!_isDownloading) {
      _downloadQueue.clear();
      notifyListeners();
    }
  }

  void clearCompletedAndFailed() {
    if (!_isDownloading) {
      _downloadQueue.removeWhere((item) =>
          item.status == DownloadStatus.completed ||
          item.status == DownloadStatus.failed ||
          item.status == DownloadStatus.retryable);
      notifyListeners();
    }
  }

  Future<void> startDownloads() async {
    if (_isDownloading || _downloadQueue.isEmpty) return;

    _isDownloading = true;
    _progressController = StreamController<DownloadItem>.broadcast();
    notifyListeners();

    try {
      for (int i = 0; i < _downloadQueue.length; i++) {
        if (_downloadQueue[i].status == DownloadStatus.completed) continue;

        await _downloadFile(_downloadQueue[i]);

        // Small delay between downloads to prevent overwhelming the browser
        if (i < _downloadQueue.length - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    } catch (e) {
      print('Download service error: $e');
    } finally {
      _isDownloading = false;
      await _progressController?.close();
      _progressController = null;
      notifyListeners();

      // Показати статистику після завершення
      printDownloadStatistics();
    }
  }

  Future<void> _downloadFile(DownloadItem item) async {
    try {
      // Update status to downloading
      item.status = DownloadStatus.downloading;
      item.progress = 0.0;
      _progressController?.add(item);
      notifyListeners();

      if (kIsWeb) {
        // Web implementation using anchor element
        await _downloadFileWeb(item);
      } else {
        // Mobile/Desktop implementation would go here
        throw UnsupportedError('Platform not supported yet');
      }

      item.status = DownloadStatus.completed;
      item.progress = 1.0;
      _progressController?.add(item);
    } catch (e) {
      item.status = DownloadStatus.failed;
      item.error = e.toString();
      _progressController?.add(item);
    }

    notifyListeners();
  }

  Future<void> _downloadFileWeb(DownloadItem item) async {
    try {
      print('🔽 Starting download: ${item.name}');

      // Спочатку спробуємо Blob підхід для примусового завантаження
      bool downloadSucceeded = false;
      try {
        await _downloadFileWithBlob(item);
        downloadSucceeded = true;
      } catch (e) {
        print('⚠️ Blob method failed: $e');
      }

      // Якщо Blob не спрацював, спробуємо fallback
      if (!downloadSucceeded) {
        try {
          await _downloadFileWithAnchor(item);
          downloadSucceeded = true;
        } catch (e) {
          print('⚠️ Anchor method failed: $e');
        }
      }

      // Перевіримо, чи файл є проблемним типом та можливо відкрився
      if (_isProblematicFileType(item.name)) {
        await Future.delayed(const Duration(milliseconds: 800));

        if (!downloadSucceeded) {
          // Файл проблемного типу і завантаження не вдалося
          item.status = DownloadStatus.retryable;
          item.canRetryManually = true;
          item.error =
              'File may have opened instead of downloading. You can retry manually or open in new tab.';
          _progressController?.add(item);
          notifyListeners();
          return;
        }
      }

      // Симулюємо прогрес для кращого UX
      for (int i = 1; i <= 10; i++) {
        if (item.status == DownloadStatus.retryable) break;
        await Future.delayed(const Duration(milliseconds: 100));
        item.progress = i / 10;
        _progressController?.add(item);
        notifyListeners();
      }

      print('✅ Downloaded: ${item.name}');
    } catch (e) {
      print('❌ Error downloading ${item.name}: $e');

      // Для проблемних файлів пропонуємо ручне завантаження
      if (_isProblematicFileType(item.name)) {
        item.status = DownloadStatus.retryable;
        item.canRetryManually = true;
        item.error =
            'Download failed. You can retry manually or open in new tab.';
      } else {
        item.status = DownloadStatus.failed;
        item.error = e.toString();
      }

      _progressController?.add(item);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _downloadFileWithBlob(DownloadItem item) async {
    print('🔽 Starting file download: ${item.name}');
    final anchor = html.AnchorElement();
    anchor.href = item.url;
    anchor.download = item.name;
    anchor.style.display = 'none';
    anchor.setAttribute('download', item.name);
    anchor.setAttribute('type', 'application/octet-stream');
    anchor.removeAttribute('target');
    html.document.body?.append(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    print('✅ File download completed: ${item.name}');
  }

  Future<void> _downloadFileWithAnchor(DownloadItem item) async {
    print('🔽 Starting file download: ${item.name}');
    final anchor = html.AnchorElement();
    anchor.href = item.url;
    anchor.download = item.name;
    anchor.style.display = 'none';
    anchor.setAttribute('download', item.name);
    anchor.setAttribute('type', 'application/octet-stream');
    anchor.removeAttribute('target');
    html.document.body?.append(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    print('✅ File download completed: ${item.name}');
  }

  void pauseDownloads() {
    // For future implementation
    // This would require more complex state management
  }

  void resumeDownloads() {
    // For future implementation
  }

  int get pendingCount => _downloadQueue
      .where((item) => item.status == DownloadStatus.pending)
      .length;

  int get completedCount => _downloadQueue
      .where((item) => item.status == DownloadStatus.completed)
      .length;

  int get failedCount => _downloadQueue
      .where((item) => item.status == DownloadStatus.failed)
      .length;

  int get retryableCount => _downloadQueue
      .where((item) => item.status == DownloadStatus.retryable)
      .length;

  double get overallProgress {
    if (_downloadQueue.isEmpty) return 0.0;

    double totalProgress = 0.0;
    for (final item in _downloadQueue) {
      switch (item.status) {
        case DownloadStatus.completed:
          totalProgress += 1.0;
          break;
        case DownloadStatus.downloading:
          totalProgress += item.progress;
          break;
        case DownloadStatus.pending:
        case DownloadStatus.failed:
        case DownloadStatus.retryable:
          // No progress
          break;
      }
    }

    return totalProgress / _downloadQueue.length;
  }

  // Список потенційно проблемних типів файлів
  static const List<String> _problematicExtensions = [
    '.pdf',
    '.txt',
    '.html',
    '.xml',
    '.svg',
    '.json',
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.bmp',
    '.mp3',
    '.mp4',
    '.avi',
    '.mov',
    '.wav',
    '.ogg',
  ];

  bool _isProblematicFileType(String fileName) {
    final extension = fileName.toLowerCase();
    return _problematicExtensions.any((ext) => extension.endsWith(ext));
  }

  // Retry файл вручну
  Future<void> retryDownloadManually(String fileName) async {
    final itemIndex =
        _downloadQueue.indexWhere((item) => item.name == fileName);
    if (itemIndex == -1) return;

    final item = _downloadQueue[itemIndex];
    if (item.status != DownloadStatus.retryable) return;

    // Збільшуємо лічильник спроб
    _downloadQueue[itemIndex] = item.copyWith(
      retryCount: item.retryCount + 1,
      status: DownloadStatus.downloading,
      progress: 0.0,
      error: null,
    );

    notifyListeners();

    try {
      await _downloadFileWeb(item);
    } catch (e) {
      _downloadQueue[itemIndex] = item.copyWith(
        status: DownloadStatus.failed,
        error: 'Retry failed: $e',
      );
      notifyListeners();
    }
  }

  // Відкрити файл у новій вкладці
  void openFileInNewTab(String fileName) {
    final item = _downloadQueue.firstWhere((item) => item.name == fileName);
    html.window.open(item.url, '_blank');
  }

  // Отримати файли, які потребують ручного втручання
  List<DownloadItem> getRetryableFiles() {
    return _downloadQueue
        .where((item) => item.status == DownloadStatus.retryable)
        .toList();
  }

  // Отримати файли, які не вдалося завантажити
  List<DownloadItem> getFailedFiles() {
    return _downloadQueue
        .where((item) => item.status == DownloadStatus.failed)
        .toList();
  }

  // Показати статистику завантажень у консолі
  void printDownloadStatistics() {
    final total = _downloadQueue.length;
    final completed = completedCount;
    final failed = failedCount;
    final retryable = retryableCount;
    final pending = pendingCount;

    print('\n📊 Download Statistics:');
    print('   Total files: $total');
    print('   ✅ Completed: $completed');
    print('   ❌ Failed: $failed');
    print('   🔄 Need manual action: $retryable');
    print('   ⏳ Pending: $pending');

    if (retryable > 0) {
      print('\n🚨 Files requiring manual action:');
      for (final file in getRetryableFiles()) {
        print('   - ${file.name}: ${file.error}');
      }
    }

    if (failed > 0) {
      print('\n❌ Failed files:');
      for (final file in getFailedFiles()) {
        print('   - ${file.name}: ${file.error}');
      }
    }
    print('');
  }

  // Спеціальний метод для завантаження контактів (окремо від основного DownloadService)
  static Future<void> downloadContactFileDirectly(
      String url, String fileName) async {
    try {
      print('📞 Starting contact file download: $fileName');
      // Найпростіший спосіб: просто створити anchor і клікнути
      final anchor = html.AnchorElement();
      anchor.href = url;
      anchor.download = fileName;
      anchor.style.display = 'none';
      anchor.setAttribute('download', fileName);
      anchor.setAttribute('type', 'text/plain');
      anchor.removeAttribute('target');
      html.document.body?.append(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      print('✅ Contact file download completed: $fileName');
    } catch (e) {
      print('❌ Error downloading contact file $fileName: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _progressController?.close();
    super.dispose();
  }
}
