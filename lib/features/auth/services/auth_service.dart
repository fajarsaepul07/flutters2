import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/shared_prefs.dart';
import '../data/models/user_model.dart';

class AuthService {

  static const String baseUrl = AppConstants.baseUrl;
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await ApiService.post(
        AppConstants.loginEndpoint,
        {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final userData = data['user'];

        await SharedPrefs.saveToken(token);

        Fluttertoast.showToast(
          msg: "Login berhasil ✓",
          backgroundColor: Colors.green,
        );

        return {'token': token, 'user': UserModel.fromJson(userData)};
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

  static Future<Map<String, dynamic>?> googleLogin() async {
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: '332481185302-kslucfiku8vlmgn5rae70kilmmsdpirv.apps.googleusercontent.com',
      scopes: ['email', 'profile'],
    );

    GoogleSignInAccount? googleUser = await googleSignIn.signInSilently();
    if (googleUser == null) {
      googleUser = await googleSignIn.signIn();
    }

    if (googleUser == null) {
      Fluttertoast.showToast(msg: "Login Google dibatalkan", backgroundColor: Colors.orange);
      return null;
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final String? idToken = googleAuth.idToken;

    if (idToken == null) {
      Fluttertoast.showToast(msg: "Gagal mendapatkan ID Token", backgroundColor: Colors.red);
      return null;
    }

    final response = await ApiService.post(
      '/auth/google',
      {'id_token': idToken},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await SharedPrefs.saveToken(data['token']);

      Fluttertoast.showToast(
        msg: "Login Google berhasil ✓",
        backgroundColor: Colors.green,
      );

      return data;
    } else {
      final error = jsonDecode(response.body);
      Fluttertoast.showToast(
        msg: error['message'] ?? "Login Google gagal",
        backgroundColor: Colors.red,
      );
    }
  } catch (e) {
    print("Google Login Error: $e");
    Fluttertoast.showToast(msg: "Google error: $e", backgroundColor: Colors.red);
  }
  return null;
}
}