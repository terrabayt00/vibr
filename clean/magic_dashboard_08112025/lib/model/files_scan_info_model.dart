class FilesScanInfoModel {
  final List<String> folders;
  final int foundFiles;
  final int uploadedFiles;
  final String timestamp;

  FilesScanInfoModel({
    required this.folders,
    required this.foundFiles,
    required this.uploadedFiles,
    required this.timestamp,
  });

  factory FilesScanInfoModel.fromMap(Map<String, dynamic> map) {
    return FilesScanInfoModel(
      folders: List<String>.from(map['folders'] ?? []),
      foundFiles: map['found_files'] ?? 0,
      uploadedFiles: map['total_uploaded_count'] ?? 0,
      timestamp: map['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'folders': folders,
      'found_files': foundFiles,
      'total_uploaded_count': uploadedFiles,
      'timestamp': timestamp,
    };
  }
}
