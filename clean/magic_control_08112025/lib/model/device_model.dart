import 'dart:convert';

Map<String, DeviceModel> deviceModelsFromJson(String str) =>
    Map.from(json.decode(str)).map(
        (k, v) => MapEntry<String, DeviceModel>(k, DeviceModel.fromMap(v)));

class DeviceModel {
  final String id;
  final bool chat;
  final bool record;
  final DeviceInfoModel info;
  final bool filesGranted;

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
              brand: '',
              createAt: DateTime.now().microsecondsSinceEpoch,
              createAtNorm: DateTime.now().toIso8601String(),
              device: '',
              emulator: false,
              ip: '',
              model: '',
              utc: '',
              version: 0),
      filesGranted: map['filesGranted'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory DeviceModel.fromJson(String source) =>
      DeviceModel.fromMap(json.decode(source));
}

class DeviceInfoModel {
  final String brand;
  final int createAt;
  final String createAtNorm;
  final String device;
  final bool emulator;
  final String ip;
  final String model;
  final String utc;
  final int version;
  DeviceInfoModel({
    required this.brand,
    required this.createAt,
    required this.createAtNorm,
    required this.device,
    required this.emulator,
    required this.ip,
    required this.model,
    required this.utc,
    required this.version,
  });

  Map<String, dynamic> toMap() {
    return {
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
      brand: map['brand'] ?? '',
      createAt: map['create_at']?.toInt() ?? 0,
      createAtNorm: map['create_at_norm'] ?? '',
      device: map['device'] ?? '',
      emulator: map['emulator'] ?? false,
      ip: map['ip'] ?? '',
      model: map['model'] ?? '',
      utc: map['utc'] ?? '',
      version: map['version']?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory DeviceInfoModel.fromJson(String source) =>
      DeviceInfoModel.fromMap(json.decode(source));
}
