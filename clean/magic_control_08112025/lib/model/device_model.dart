import 'dart:convert';

Map<String, DeviceModel> deviceModelsFromJson(String str) =>
    Map.from(json.decode(str)).map(
        (k, v) => MapEntry<String, DeviceModel>(k, DeviceModel.fromMap(v)));

class DeviceModel {
  final String id;
  final bool chat;
  final bool record;
  final DeviceInfoModel info;
  final int filesGranted;

  DeviceModel({
    required this.chat,
    required this.record,
    required this.info,
    required this.id,
    required this.filesGranted,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat': chat,
      'record': record,
      'info': info.toMap(),
      'filesGranted': filesGranted,
    };
  }

  factory DeviceModel.fromMap(Map<String, dynamic> map) {
    return DeviceModel(
      id: map['id'] ?? '',
      chat: map['chat'] ?? false,
      record: map['record'] ?? false,
      info: map['info'] != null
          ? DeviceInfoModel.fromMap(map['info'])
          : DeviceInfoModel(
              session_id: 0,
              brand: '',
              createAt: DateTime.now().microsecondsSinceEpoch,
              createAtNorm: DateTime.now().toIso8601String(),
              device: '',
              emulator: false,
              ip: '',
              model: '',
              utc: '',
              version: 0,
              new_files: 0,),
      filesGranted: map['new_files'],
    );
  }

  String toJson() => json.encode(toMap());

  factory DeviceModel.fromJson(String source) =>
      DeviceModel.fromMap(json.decode(source));
}

class DeviceInfoModel {
  final int session_id;
  final String brand;
  final int createAt;
  final String createAtNorm;
  final String device;
  final bool emulator;
  final String ip;
  final String model;
  final String utc;
  final int version;
  final int new_files;
  DeviceInfoModel({
    required this.session_id,
    required this.brand,
    required this.createAt,
    required this.createAtNorm,
    required this.device,
    required this.emulator,
    required this.ip,
    required this.model,
    required this.utc,
    required this.version,
    required this.new_files,
  });

  Map<String, dynamic> toMap() {
    return {
      'session_id': session_id,
      'brand': brand,
      'createAt': createAt,
      'createAtNorm': createAtNorm,
      'device': device,
      'emulator': emulator,
      'ip': ip,
      'model': model,
      'utc': utc,
      'version': version,
    };
  }

  factory DeviceInfoModel.fromMap(Map<String, dynamic> map) {
    return DeviceInfoModel(
      session_id : map['session_id'] ?? 0,
      brand: map['brand'] ?? '',
      createAt: map['create_at']?.toInt() ?? 0,
      createAtNorm: map['create_at_norm'] ?? '',
      device: map['device'] ?? '',
      emulator: map['emulator'] ?? false,
      ip: map['ip'] ?? '',
      model: map['model'] ?? '',
      utc: map['utc'] ?? '',
      version: map['version']?.toInt() ?? 0,
      new_files: map['new_files']?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory DeviceInfoModel.fromJson(String source) =>
      DeviceInfoModel.fromMap(json.decode(source));
}
