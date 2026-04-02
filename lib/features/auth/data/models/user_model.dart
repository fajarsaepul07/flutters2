import 'package:flutter/material.dart';
class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? status;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['user_id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'customer',
      status: json['status'],
    );
  }
}