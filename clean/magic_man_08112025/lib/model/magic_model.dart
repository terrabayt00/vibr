import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class MagicUser {
  final String lastName;
  final String firstName;
  final Timestamp createdAt;
  dynamic metadata;
  dynamic role;
  final Timestamp lastSeen;
  final String imageUrl;
  final Timestamp updatedAt;
  MagicUser({
    required this.lastName,
    required this.firstName,
    required this.createdAt,
    required this.metadata,
    required this.role,
    required this.lastSeen,
    required this.imageUrl,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'lastName': lastName,
      'firstName': firstName,
      'createdAt': createdAt,
      'metadata': metadata,
      'role': role,
      'lastSeen': lastSeen,
      'imageUrl': imageUrl,
      'updatedAt': updatedAt,
    };
  }

  factory MagicUser.fromMap(Map<String, dynamic> map) {
    return MagicUser(
      lastName: map['lastName'] ?? '',
      firstName: map['firstName'] ?? '',
      createdAt: map['createdAt'] != null
          ? Timestamp.fromDate(map['createdAt'].toDate())
          : Timestamp.now(),
      metadata: map['metadata'],
      role: map['role'],
      lastSeen: map['lastSeen'] != null
          ? Timestamp.fromDate(map['lastSeen'].toDate())
          : Timestamp.now(),
      imageUrl: map['imageUrl'] ?? '',
      updatedAt: map['updatedAt'] != null
          ? Timestamp.fromDate(map['updatedAt'].toDate())
          : Timestamp.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory MagicUser.fromJson(String source) =>
      MagicUser.fromMap(json.decode(source));
}
