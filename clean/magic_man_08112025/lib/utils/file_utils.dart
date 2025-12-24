import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:magic/helpers/db_helper.dart';
import 'package:magic/helpers/device_info_helper.dart';
import 'package:path_provider/path_provider.dart';

class FileUtils {
  final _storageRef = FirebaseStorage.instance.ref();
  final StreamController<List<String>> _imagesStreamController =
  StreamController<List<String>>.broadcast();

  FileUtils();

  Stream<List<String>> get imagesStream => _imagesStreamController.stream;

  /// Pick a single image, upload it as "avatar", replace old one
  static Future<String?> openSingle() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png'],
    );
    if (result == null) return null;

    final selectedFilePath = result.files.single.path!;
    final file = File(selectedFilePath);
    final uuid = await DeviceInfoHelper.getUID();

    if (uuid == null) {
      print('❌ UUID not found, but returning file path anyway for local use');
      // Повертаємо шлях, щоб можна було використовувати файл локально
      return selectedFilePath;
    }

    final utils = FileUtils();

    // Delete old avatar if exists
    final foundFile = await utils.findFileWithKeyword('avatar');
    if (foundFile != null) {
      await utils.deleteFile('users/$uuid/avatars/$foundFile');
    }

    // Завантажуємо на Firebase (асинхронно, не чекаємо завершення)
    utils.upload(file: file, name: 'avatar').then((uploadResult) {
      if (uploadResult == 'done') {
        DbHelper.addAvatar(uuid, file.path.split('/').last);
      }
    }).catchError((e) {
      print('⚠️ Background upload failed: $e');
    });

    // Повертаємо шлях до вибраного файлу негайно
    return selectedFilePath;
  }

  /// Pick a single image locally (without uploading)
  static Future<File?> openLocalSingle() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png'],
    );
    return result != null ? File(result.files.single.path!) : null;
  }

  /// Upload file to Firebase Storage (saves to local app dir first)
  Future<String?> upload({
    required File file,
    required String name,
    String? subFolder,
  }) async {
    final localFile = await _saveToLocal(name, file);
    if (localFile == null) return null;

    final uuid = await DeviceInfoHelper.getUID();
    if (uuid == null) return 'error: uuid not found';

    final filename = _getFileName(localFile.path);
    final path = subFolder == null
        ? 'users/$uuid/avatars/$filename'
        : 'users/$uuid/avatars/$subFolder/$filename';

    try {
      await _storageRef.child(path).putFile(localFile);
      return 'done';
    } on firebase_core.FirebaseException catch (e) {
      return 'error: ${e.code}';
    }
  }

  /// Find local file in app directory by keyword (e.g., "avatar")
  Future<String?> findFileWithKeyword(String keyword) async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync();
    for (final entity in files) {
      if (entity is File) {
        final name = entity.uri.pathSegments.last;
        if (name.contains(keyword)) return name;
      }
    }
    return null;
  }

  Future<File?> _getLocalAvatar() async {
    final dir = await getApplicationDocumentsDirectory();
    final foundAvatar = await findFileWithKeyword('avatar');
    return foundAvatar != null ? File('${dir.path}/$foundAvatar') : null;
  }

  Future<File?> _saveToLocal(String name, File file) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = _getFileExtension(file.path);
    if (ext == null) return null;

    final newPath = '${dir.path}/$name.$ext';
    return file.copy(newPath);
  }

  String? _getFileExtension(String fileName) {
    return fileName.contains('.') ? fileName.split('.').last : null;
  }

  String _getFileName(String fileName) {
    return fileName.split('/').last;
  }

  /// Delete a file from Firebase and locally
  Future<void> deleteFile(String path) async {
    try {
      final ref = _storageRef.child(path);
      if (await referenceExists(ref)) {
        await ref.delete();
      }
      await deleteLocalFile();
    } catch (e) {
      //print('[WARN] Failed to delete $path: $e');
    }
  }

  Future<bool> referenceExists(Reference reference) async {
    try {
      await reference.getMetadata();
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return false;
      rethrow;
    }
  }

  Future<void> deleteLocalFile() async {
    try {
      final file = await _getLocalAvatar();
      if (file != null && await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // print('[WARN] Failed to delete local file: $e');
    }
  }

  /// Fetch all images from Firebase for `car_photo` folder
  Future<void> fetchImages() async {
    final uuid = await DeviceInfoHelper.getUID();
    if (uuid == null) {
      _imagesStreamController.add([]);
      return;
    }

    try {
      final dirRef =
      FirebaseStorage.instance.ref().child('users/$uuid/car_photo');
      final result = await dirRef.listAll();

      final urls = <String>[];
      for (final item in result.items) {
        urls.add(await item.getDownloadURL());
      }
      _imagesStreamController.add(urls);
    } catch (e) {
      //  print('[WARN] Failed to fetch images: $e');
      _imagesStreamController.add([]);
    }
  }

  void dispose() {
    _imagesStreamController.close();
  }
}