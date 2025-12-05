import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'storage_interface.dart';

class FirebaseStorageService implements StorageInterface {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Future<String?> uploadFile({
    required File file,
    required String path,
    Map<String, String>? metadata,
  }) async {
    try {
      final ref = _storage.ref().child(path);

      UploadTask uploadTask;
      if (metadata != null) {
        final settableMetadata = SettableMetadata(
          customMetadata: metadata,
          contentType: _getContentType(file.path),
        );
        uploadTask = ref.putFile(file, settableMetadata);
      } else {
        uploadTask = ref.putFile(file);
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      // Silent fail - return null on error
      return null;
    }
  }

  @override
  Future<File?> downloadFile({
    required String url,
    required String localPath,
  }) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final file = File(localPath);
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> deleteFile(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String?> getDownloadUrl(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> fileExists(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.getMetadata();
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> getFileMetadata(String path) async {
    try {
      final ref = _storage.ref().child(path);
      final metadata = await ref.getMetadata();
      return {
        'size': metadata.size,
        'contentType': metadata.contentType,
        'created': metadata.timeCreated?.toIso8601String(),
        'updated': metadata.updated?.toIso8601String(),
        'customMetadata': metadata.customMetadata,
      };
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<String?>> uploadBatch({
    required List<File> files,
    required List<String> paths,
    Map<String, String>? metadata,
  }) async {
    final results = <String?>[];

    for (int i = 0; i < files.length; i++) {
      final result = await uploadFile(
        file: files[i],
        path: paths[i],
        metadata: metadata,
      );
      results.add(result);
    }

    return results;
  }

  /// Helper method to determine content type
  String _getContentType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'json':
        return 'application/json';
      case 'mp4':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mpeg';
      default:
        return 'application/octet-stream';
    }
  }
}
