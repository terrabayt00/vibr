class FileInfoModel {
  final String name;
  final String path;
  final String type;
  String? uploaded;

  FileInfoModel({
    required this.name,
    this.uploaded,
    required this.path,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'path': path,
      'type': type,
      'uploaded': uploaded ?? ''
    };
  }
}
