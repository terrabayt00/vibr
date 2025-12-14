class FileUploadStats {
  final int filesSkipped;
  final bool isComplete;
  final String lastUpdate;
  final int remainingFiles;
  final String scanType;
  final int totalFiles;
  final String uploadPercentage;
  final int uploadedFiles;

  FileUploadStats({
    required this.filesSkipped,
    required this.isComplete,
    required this.lastUpdate,
    required this.remainingFiles,
    required this.scanType,
    required this.totalFiles,
    required this.uploadPercentage,
    required this.uploadedFiles,
  });

  factory FileUploadStats.fromJson(Map<String, dynamic> json) =>
      FileUploadStats(
        filesSkipped: json["files_skipped"] ?? 0,
        isComplete: json["is_complete"] ?? false,
        lastUpdate: json["last_update"] ?? "",
        remainingFiles: json["remaining_files"] ?? 0,
        scanType: json["scan_type"] ?? "",
        totalFiles: json["total_files"] ?? 0,
        uploadPercentage: json["upload_percentage"] ?? "0",
        uploadedFiles: json["uploaded_files"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
    "files_skipped": filesSkipped,
    "is_complete": isComplete,
    "last_update": lastUpdate,
    "remaining_files": remainingFiles,
    "scan_type": scanType,
    "total_files": totalFiles,
    "upload_percentage": uploadPercentage,
    "uploaded_files": uploadedFiles,
  };
}