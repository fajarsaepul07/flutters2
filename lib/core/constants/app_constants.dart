import 'package:flutter/material.dart';
class AppConstants {
  // Untuk Chrome (Web) gunakan ini dulu
  static const String baseUrl = "http://localhost:8000/api";

  // Kalau nanti pakai Android Emulator, ganti jadi:
  // static const String baseUrl = "http://10.0.2.2:8000/api";

  static const String loginEndpoint = "/login";
}