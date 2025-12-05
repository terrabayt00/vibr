import 'package:firebase_storage/firebase_storage.dart';
import 'dart:html' as html;

class StorageHelper {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<List<Map<String, String>>> listFilesWithUrls(String path) async {
    final Reference ref = _storage.ref(path);
    final ListResult result = await ref.listAll();

    List<Map<String, String>> files = [];

    for (var item in result.items) {
      try {
        final url = await item.getDownloadURL(); // Отримує signed URL
        files.add({'name': item.name, 'url': url});
      } catch (e) {
        print('Error fetching URL for ${item.name}: $e');
      }
    }
    return files;
  }

  Future<List<String>> listFilesAndFolders(String path, bool isFolder) async {
    final Reference ref = _storage.ref(path);
    final ListResult result = await ref.listAll();
    List<String> list = [];

    if (isFolder) {
      for (var prefix in result.prefixes) {
        list.add(prefix.name);
      }
    } else {
      for (var item in result.items) {
        list.add(item.name);
      }
    }
    return list;
  }

  Future<bool> checkIfPathExists(String path) async {
    try {
      final ref = _storage.ref(path);
      final result = await ref.list(const ListOptions(maxResults: 1));
      return result.items.isNotEmpty || result.prefixes.isNotEmpty;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return false;
      rethrow;
    }
  }

  void launchLink(String link) {
    html.window.open(link, '_blank'); // Для Web
  }
}
