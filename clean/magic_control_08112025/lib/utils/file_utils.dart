import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:magic_control/helper/db_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart' as firebase_core;

class FileUtils {
  final _storageRef = FirebaseStorage.instance.ref();
  static Future<String?> openSingle() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? uuid = user.uid;

        String? foundFile = await FileUtils().findFileWithKeyword('avatar');
        if (foundFile != null) {
          await FileUtils().deleteFile('drivers/$uuid/$foundFile');
        }
        String? resUpload =
            await FileUtils().upload(file: file, name: 'avatar');
        if (resUpload != null && resUpload == 'done') {
          //set avatar
          DbHelper db = DbHelper();
          await db.addAvatar(uuid, file.path.split('/').last);
          return 'done';
        } else {
          return resUpload;
        }
      }
    } else {
      // User canceled the picker
      return null;
    }
    return null;
  }

  Future<String?> findFileWithKeyword(String keyword) async {
    Directory appDirectory = await getApplicationDocumentsDirectory();
    List<FileSystemEntity> files = appDirectory.listSync();

    for (FileSystemEntity file in files) {
      if (file is File) {
        String fileName = file.uri.pathSegments.last;
        if (fileName.contains(keyword)) {
          return _getFileName(file.path);
        }
      }
    }

    return null;
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File?> get _localFile async {
    final path = await _localPath;

    String? foundAvatar = await findFileWithKeyword('avatar');
    if (foundAvatar != null) {
      return File('$path/$foundAvatar');
    }
    return null;
  }

  String _getFileName(String fileName) {
    try {
      return fileName.split('/').last;
    } catch (e) {
      return 'error.jpg';
    }
  }

  Future<File?> _saveToLocal(String name, File file) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();

    String? fileType = _getFileExtension(file.path);

    if (fileType != null) {
      String path = appDocDir.path;
      String newPath = '$path/$name.$fileType';
      File fileLocal = await file.copy(newPath);
      return fileLocal;
    }
    return null;
  }

  String? _getFileExtension(String fileName) {
    try {
      return fileName.split('.').last;
    } catch (e) {
      return null;
    }
  }

  //!Upload file
  Future<String?> upload({
    required File file,
    required String name,
    String? subFolder,
  }) async {
    File? localFile = await _saveToLocal(name, file);
    if (localFile == null) return null;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uuid = user.uid;

      String filename = _getFileName(localFile.path);

      final driverRef = _storageRef.child(subFolder == null
          ? 'drivers/$uuid/$filename'
          : 'drivers/$uuid/$subFolder/$filename');
      try {
        await driverRef.putFile(localFile);
        return 'done';
      } on firebase_core.FirebaseException catch (e) {
        return 'error: $e';
      }
    }
    return null;
  }

  //! Detete
  Future<void> deleteFile(String path) async {
    try {
      print('Path delete file: $path');
      final desertRef = _storageRef.child(path);
      final bool existRef = await referenceExists(desertRef);
      if (existRef) {
        await desertRef.delete();
        await deleteLocalFile();
      }
    } catch (e) {
      print('Error delete $e');
    }
  }

  Future<bool> referenceExists(Reference reference) async {
    try {
      await reference.getMetadata();
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return false;
      } else {
        rethrow;
      }
    }
  }

  Future<void> deleteLocalFile() async {
    try {
      File? file = await _localFile;
      if (file != null) {
        await file.delete();
      }
    } catch (e) {
      print('Error delete local file $e');
    }
  }
}
