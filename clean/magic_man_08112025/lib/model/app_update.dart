class AppUpdate {
  final int versionCode;
  final String downloadUrl;

  const AppUpdate({required this.versionCode, required this.downloadUrl});

  Map<String, dynamic> toMap() {
    return {
      'versionCode': this.versionCode,
      'downloadUrl': this.downloadUrl,
    };
  }

  factory AppUpdate.fromMap(Map<dynamic, dynamic> map) {
    return AppUpdate(
      versionCode: map['versionCode'] as int,
      downloadUrl: map['apkFileUrl'] as String? ?? "",
    );
  }
}
