import 'dart:convert';

Map<String, GirlModel> girlsModelFromJson(String str) =>
    Map.from(json.decode(str))
        .map((k, v) => MapEntry<String, GirlModel>(k, GirlModel.fromMap(v)));

class GirlModel {
  final String id;
  final String firstName;
  final String imageUrl;
  final String lastName;
  final String email;
  final bool isActive;
  GirlModel({
    required this.id,
    required this.firstName,
    required this.imageUrl,
    required this.lastName,
    required this.email,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'imageUrl': imageUrl,
      'lastName': lastName,
      'email': email,
      'isActive': isActive,
    };
  }

  factory GirlModel.fromMap(Map<String, dynamic> map) {
    return GirlModel(
      id: map['id'] ?? '',
      firstName: map['firstName'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      isActive: map['isActive'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory GirlModel.fromJson(String source) =>
      GirlModel.fromMap(json.decode(source));
}
