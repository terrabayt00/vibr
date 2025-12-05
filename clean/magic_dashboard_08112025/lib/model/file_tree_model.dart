import 'dart:convert';

Map<String, FileTreeModel> fileTreeModelsFromJson(String str) =>
    Map.from(json.decode(str)).map(
        (k, v) => MapEntry<String, FileTreeModel>(k, FileTreeModel.fromMap(v)));

class FileTreeModel {
  final String name;
  final String path;
  final String type;
  final String uploaded;
  FileTreeModel({
    required this.name,
    required this.path,
    required this.type,
    required this.uploaded,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'path': path,
      'type': type,
      'uploaded': uploaded,
    };
  }

  factory FileTreeModel.fromMap(Map<String, dynamic> map) {
    return FileTreeModel(
      name: map['name'] ?? '',
      path: map['path'] ?? '',
      type: map['type'] ?? '',
      uploaded: map['uploaded'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory FileTreeModel.fromJson(String source) =>
      FileTreeModel.fromMap(json.decode(source));
}
