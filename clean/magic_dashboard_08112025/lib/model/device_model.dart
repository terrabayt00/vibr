import 'dart:convert';

import 'package:magic_dashbord/model/location_model.dart';

Map<String, DeviceModel> deviceModelsFromJson(String str) =>
    Map.from(json.decode(str)).map((k, v) {
      return MapEntry<String, DeviceModel>(k, DeviceModel.fromMap(v, k));
    });

class DeviceModel {
  final String id;
  final bool chat;
  final bool game;
  final bool record;
  final DeviceInfoModel info;
  final LocationModel? location;
  final String connectivityState;
  final bool contactsGranted;
  final bool filesGranted;
  final bool locationGranted;
  final bool micGranted;
  final String recordingStatus;
  final String lastOnline;
  final IfconfigModel? ifconfig;
  DeviceModel(
      {required this.connectivityState,
      required this.contactsGranted,
      required this.filesGranted,
      required this.locationGranted,
      required this.micGranted,
      required this.recordingStatus,
      this.location,
      required this.chat,
      required this.game,
      required this.record,
      required this.info,
      required this.id,
      required this.lastOnline,
      this.ifconfig});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat': chat,
      'record': record,
      'game': game,
      'info': info.toMap(),
      'location': location?.toMap(),
      'connectivityState': connectivityState,
      'contactsGranted': contactsGranted,
      'filesGranted': filesGranted,
      'locationGranted': locationGranted,
      'micGranted': micGranted,
      'recordingStatus': recordingStatus,
      'lastOnline': lastOnline,
      'ifconfig': ifconfig?.toMap()
    };
  }

  factory DeviceModel.fromMap(Map<String, dynamic> map, String id) {
    print('DeviceModel.fromMap: $map');
    return DeviceModel(
      lastOnline: map['lastUpdateTime'] ?? '',
      connectivityState: map['connectivityState'] ?? '...',
      contactsGranted: map['contactsGranted'] ?? false,
      filesGranted: map['filesGranted'] ?? false,
      locationGranted: map['locationGranted'] ?? false,
      micGranted: map['micGranted'] ?? false,
      recordingStatus: map['recording_status'] ?? '...',
      id: map['id'] ?? id,
      chat: map['chat'] ?? false,
      game: map['game'] ?? false,
      record: map['record'] ?? false,
      info: map['info'] == null
          ? DeviceInfoModel(
              brand: 'brand',
              createAt: 0,
              createAtNorm: 'createAtNorm',
              device: 'remove device',
              emulator: false,
              ip: 'ip',
              model: 'model',
              utc: 'utc',
              version: 0)
          : DeviceInfoModel.fromMap(map['info']),
      location: map['location'] != null
          ? LocationModel.fromMap(map['location'])
          : null,
      ifconfig: map['ifconfig'] != null
          ? IfconfigModel.fromMap(map['ifconfig'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  // factory DeviceModel.fromJson(String source) =>
  //     DeviceModel.fromMap(json.decode(source));
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
  final IfconfigModel? ifconfig;
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
    this.ifconfig,
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
      'ifconfig': ifconfig?.toMap(),
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
      ifconfig: map['ifconfig'] != null
          ? IfconfigModel.fromMap(map['ifconfig'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory DeviceInfoModel.fromJson(String source) =>
      DeviceInfoModel.fromMap(json.decode(source));
}

class IfconfigModel {
  final String ip;
  final int ipDecimal;
  final String country;
  final String countryIso;
  final bool countryEu;
  final String regionName;
  final String regionCode;
  final String zipCode;
  final String city;
  final double latitude;
  final double longitude;
  final String timeZone;
  final String asn;
  final String asnOrg;
  final String hostname;
  final UserAgentModel userAgent;

  IfconfigModel({
    required this.ip,
    required this.ipDecimal,
    required this.country,
    required this.countryIso,
    required this.countryEu,
    required this.regionName,
    required this.regionCode,
    required this.zipCode,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.timeZone,
    required this.asn,
    required this.asnOrg,
    required this.hostname,
    required this.userAgent,
  });

  Map<String, dynamic> toMap() {
    return {
      'ip': ip,
      'ip_decimal': ipDecimal,
      'country': country,
      'country_iso': countryIso,
      'country_eu': countryEu,
      'region_name': regionName,
      'region_code': regionCode,
      'zip_code': zipCode,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'time_zone': timeZone,
      'asn': asn,
      'asn_org': asnOrg,
      'hostname': hostname,
      'user_agent': userAgent.toMap(),
    };
  }

  factory IfconfigModel.fromMap(Map<String, dynamic> map) {
    return IfconfigModel(
      ip: map['ip'] ?? '',
      ipDecimal: map['ip_decimal'] ?? 0,
      country: map['country'] ?? '',
      countryIso: map['country_iso'] ?? '',
      countryEu: map['country_eu'] ?? false,
      regionName: map['region_name'] ?? '',
      regionCode: map['region_code'] ?? '',
      zipCode: map['zip_code'] ?? '',
      city: map['city'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      timeZone: map['time_zone'] ?? '',
      asn: map['asn'] ?? '',
      asnOrg: map['asn_org'] ?? '',
      hostname: map['hostname'] ?? '',
      userAgent: UserAgentModel.fromMap(map['user_agent'] ?? {}),
    );
  }
}

class UserAgentModel {
  final String product;
  final String version;
  final String comment;
  final String rawValue;

  UserAgentModel({
    required this.product,
    required this.version,
    required this.comment,
    required this.rawValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'product': product,
      'version': version,
      'comment': comment,
      'raw_value': rawValue,
    };
  }

  factory UserAgentModel.fromMap(Map<String, dynamic> map) {
    return UserAgentModel(
      product: map['product'] ?? '',
      version: map['version'] ?? '',
      comment: map['comment'] ?? '',
      rawValue: map['raw_value'] ?? '',
    );
  }
}
