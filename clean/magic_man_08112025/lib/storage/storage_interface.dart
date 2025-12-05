import 'dart:io';

/// Abstract interface for file storage services
abstract class StorageInterface {
  /// Upload a file to storage and return the download URL
  Future<String?> uploadFile({
    required File file,
    required String path,
    Map<String, String>? metadata,
  });

  /// Download a file from storage
  Future<File?> downloadFile({
    required String url,
    required String localPath,
  });

  /// Delete a file from storage
  Future<bool> deleteFile(String path);

  /// Get download URL for a file
  Future<String?> getDownloadUrl(String path);

  /// Check if file exists in storage
  Future<bool> fileExists(String path);

  /// Get file metadata
  Future<Map<String, dynamic>?> getFileMetadata(String path);

  /// Upload multiple files in batch
  Future<List<String?>> uploadBatch({
    required List<File> files,
    required List<String> paths,
    Map<String, String>? metadata,
  });
}

/// Result class for upload operations
class UploadResult {
  final bool success;
  final String? downloadUrl;
  final String? error;
  final Map<String, dynamic>? metadata;

  UploadResult({
    required this.success,
    this.downloadUrl,
    this.error,
    this.metadata,
  });
}
