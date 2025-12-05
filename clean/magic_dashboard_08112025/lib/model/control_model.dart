import 'dart:convert';

Map<String, ControlModel> controlModelsFromJson(String str) =>
    Map.from(json.decode(str)).map(
        (k, v) => MapEntry<String, ControlModel>(k, ControlModel.fromJson(v)));

class ControlModel {
  final int other;
  final int modes;
  final int global;
  final int intensive;

  ControlModel({
    required this.other,
    required this.modes,
    required this.global,
    required this.intensive,
  });

  factory ControlModel.fromRawJson(String str) =>
      ControlModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ControlModel.fromJson(Map<String, dynamic> json) => ControlModel(
        other: json["other"],
        modes: json["modes"],
        global: json["global"],
        intensive: json["intensive"],
      );

  Map<String, dynamic> toJson() => {
        "other": other,
        "modes": modes,
        "global": global,
        "intensive": intensive,
      };
}
