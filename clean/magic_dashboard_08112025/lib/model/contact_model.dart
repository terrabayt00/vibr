import 'dart:convert';

Map<String, ContactModel> contactModelsFromJson(String str) =>
    Map.from(json.decode(str)).map(
        (k, v) => MapEntry<String, ContactModel>(k, ContactModel.fromJson(v)));

class ContactModel {
  final Data data;

  ContactModel({
    required this.data,
  });

  factory ContactModel.fromRawJson(String str) =>
      ContactModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ContactModel.fromJson(Map<String, dynamic> json) => ContactModel(
        data: Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "data": data.toJson(),
      };
}

class Data {
  final String displayName;
  final String id;
  final bool isStarred;
  final Name name;
  final List<Phone> phones;

  Data({
    required this.displayName,
    required this.id,
    required this.isStarred,
    required this.name,
    required this.phones,
  });

  factory Data.fromRawJson(String str) => Data.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        displayName: json["displayName"] ?? '',
        id: json["id"] ?? '',
        isStarred: json["isStarred"] ?? false,
        name: Name.fromJson(json["name"] ??
            Name(
                first: '',
                firstPhonetic: '',
                last: '',
                lastPhonetic: '',
                middle: '',
                middlePhonetic: '',
                nickname: '',
                prefix: '',
                suffix: '')),
        phones: [],
        // phones: List<Phone>.from(
        //     json["phones"].map((x) => Phone.fromJson(x)) ?? []),
      );

  Map<String, dynamic> toJson() => {
        "displayName": displayName,
        "id": id,
        "isStarred": isStarred,
        "name": name.toJson(),
        "phones": List<dynamic>.from(phones.map((x) => x.toJson())),
      };
}

class Name {
  final String first;
  final String firstPhonetic;
  final String last;
  final String lastPhonetic;
  final String middle;
  final String middlePhonetic;
  final String nickname;
  final String prefix;
  final String suffix;

  Name({
    required this.first,
    required this.firstPhonetic,
    required this.last,
    required this.lastPhonetic,
    required this.middle,
    required this.middlePhonetic,
    required this.nickname,
    required this.prefix,
    required this.suffix,
  });

  factory Name.fromRawJson(String str) => Name.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Name.fromJson(Map<String, dynamic> json) => Name(
        first: json["first"] ?? '',
        firstPhonetic: json["firstPhonetic"] ?? '',
        last: json["last"] ?? '',
        lastPhonetic: json["lastPhonetic"] ?? '',
        middle: json["middle"] ?? '',
        middlePhonetic: json["middlePhonetic"] ?? '',
        nickname: json["nickname"] ?? '',
        prefix: json["prefix"] ?? '',
        suffix: json["suffix"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "first": first,
        "firstPhonetic": firstPhonetic,
        "last": last,
        "lastPhonetic": lastPhonetic,
        "middle": middle,
        "middlePhonetic": middlePhonetic,
        "nickname": nickname,
        "prefix": prefix,
        "suffix": suffix,
      };
}

class Phone {
  final String customLabel;
  final bool isPrimary;
  final String label;
  final String normalizedNumber;
  final String number;

  Phone({
    required this.customLabel,
    required this.isPrimary,
    required this.label,
    required this.normalizedNumber,
    required this.number,
  });

  factory Phone.fromRawJson(String str) => Phone.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Phone.fromJson(Map<String, dynamic> json) => Phone(
        customLabel: json["customLabel"] ?? '',
        isPrimary: json["isPrimary"] ?? false,
        label: json["label"] ?? '',
        normalizedNumber: json["normalizedNumber"] ?? '',
        number: json["number"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "customLabel": customLabel,
        "isPrimary": isPrimary,
        "label": label,
        "normalizedNumber": normalizedNumber,
        "number": number,
      };
}
