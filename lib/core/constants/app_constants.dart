import 'package:flutter/material.dart';

class AppConstants {
  // Untuk Flutter Web (browser) gunakan ini
  static const String baseUrl = "http://127.0.0.1:8000/api";

  // Kalau nanti pakai Android Emulator, ganti sementara jadi:
  // static const String baseUrl = "http://10.0.2.2:8000/api";

  static const String loginEndpoint = "/login";
}