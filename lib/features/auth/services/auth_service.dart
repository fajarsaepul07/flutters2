import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/shared_prefs.dart';
import '../data/models/user_model.dart';

class AuthService {
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await ApiService.post(
        AppConstants.loginEndpoint,
        {'email': email, 'password': password},
      );

      print(response.statusCode);
print(response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final token = data['token'];
        final userData = data['user'];

        await SharedPrefs.saveToken(token);

        Fluttertoast.showToast(
          msg: "Login berhasil ✓",
          backgroundColor: Colors.green,
        );
        

        return {
          'token': token,
          'user': UserModel.fromJson(userData),
        };
      } else {
        final error = jsonDecode(response.body);
        Fluttertoast.showToast(
          msg: error['message'] ?? "Login gagal",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Koneksi error: $e", backgroundColor: Colors.red);
    }
    return null;
  }
}