import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:magic_control/model/control_model.dart';
import 'package:magic_control/model/device_model.dart';
import 'package:magic_control/model/girl_model.dart';

class DbHelper {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref('control_gear');
  final DatabaseReference _refDevice = FirebaseDatabase.instance.ref('devices');
  Stream<Map<String, ControlModel>?> fetchData() {
    return _ref.onValue.map((DatabaseEvent event) {
      var data = event.snapshot.value;

      if (data != null) {
        return controlModelsFromJson(jsonEncode(data));
      } else {
        return null;
      }
    });
  }

  Stream<Map<String, DeviceModel>?> fetchDevices() {
    return _refDevice.onValue.map((DatabaseEvent event) {
      var data = event.snapshot.value;

      if (data != null) {
        return deviceModelsFromJson(jsonEncode(data));
      } else {
        return null;
      }
    });
  }

  Stream<ControlModel?> fetchDeviceData(String id) {
    return _ref.child(id).onValue.map((DatabaseEvent event) {
      var data = event.snapshot.value;

      if (data != null) {
        return ControlModel.fromRawJson(jsonEncode(data));
      } else {
        return null;
      }
    });
  }

  Future<DeviceInfoModel?> getDeviceInfo(String id) async {
    final snapshot = await _refDevice.child('$id/info').get();
    if (snapshot.exists) {
      var data = snapshot.value;
      if (data != null) {
        return DeviceInfoModel.fromJson(jsonEncode(data));
      }
    }
    print('No data available.');
    return null;
  }

  Future<void> saveGirlId(Map<String, dynamic> data) async {
    String id = data['id'];
    DatabaseReference ref = FirebaseDatabase.instance.ref("girls/$id");
    await ref.set(data);
  }

  Future<List<GirlModel>> getGirls() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("girls");
    final snapshot = await ref.get();
    if (snapshot.exists) {
      var data = snapshot.value;
      if (data != null) {
        Map<String, GirlModel> result = girlsModelFromJson(jsonEncode(data));
        List<GirlModel> girls = result.entries.map((e) {
          GirlModel model = e.value;
          return model;
        }).toList();
        return girls;
      }
    }
    print('No data available.');
    return [];
  }

  Future<bool> checkChat(String id) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("devices/$id/chat");
    final snapshot = await ref.get();
    if (snapshot.exists) {
      var data = snapshot.value;
      if (data != null) {
        return data as bool;
      }
    }
    print('No data available.');
    return false;
  }

  Future<void> setChat(String id, bool state) async {
    DatabaseReference chatRef =
        FirebaseDatabase.instance.ref("devices/$id/chat");
    await chatRef.set(state);
  }

  Future<void> setGame(String id, bool state) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("devices/$id/game");
    await ref.set(state);
  }

  Future<void> updateGirlActive(String id, bool state) async {
    print('start update $id, state: $state');
    DatabaseReference chatRef = FirebaseDatabase.instance.ref("girls/$id");
   await chatRef.update({'isActive': state});
   
  }

  Future<String> updateMagicUser(String id, Map<String, dynamic> data) {
    CollectionReference users = FirebaseFirestore.instance.collection('users');

    return users
        .doc(id)
        .update(data)
        .then((value) => ("User Updated"))
        .catchError((error) => ("Failed to update user: $error"));
  }

  Future<void> updateGirlProfile(String id, Map<String, dynamic> data) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("girls/$id");
    await ref.update(data);
  }

  Future<void> addAvatar(String id, String name) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("drivers/$id");
    await ref.set({'avatar': name});
  }

  Future<String> getImageUrl(String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    final url = await ref.getDownloadURL();
    return url;
  }

  Future<bool> checkActiveGirl(String id) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("girls/$id/isActive");
    final snapshot = await ref.get();
    if (snapshot.exists) {
      var data = snapshot.value;
      if (data != null) {
        return data as bool;
      }
    }
    print('No data available.');
    return false;
  }

  Future<bool> checkGame(String id) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("devices/$id/game");
    final snapshot = await ref.get();
    if (snapshot.exists) {
      var data = snapshot.value;
      if (data != null) {
        return data as bool;
      }
    }
    print('No data available.');
    return false;
  }

  Future<bool> checkNewFiles(String id) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("devices/$id/new_files");
    final snapshot = await ref.get();
    if (snapshot.exists) {
      var data = snapshot.value;
      if (data != null) {
        return data as bool;
      }
    }
    print('No data available.');
    return false;
  }

  Stream<Map<String, dynamic>?> fetchProgressData(String id) {
    return FirebaseDatabase.instance
        .ref('file_uploads/$id/progress')
        .onValue
        .map((DatabaseEvent event) {
      var data = event.snapshot.value;
      if (data != null) {
        return Map<String, dynamic>.from(data as Map);
      }
      return null;
    });
  }
}
