import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../data/models/user_model.dart';
import '../services/auth_service.dart';
import '../../../core/utils/shared_prefs.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  String? _token;
  bool _isLoading = false;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null;

  // ================== LOGIN BIASA ==================
  Future<bool> login(String email, String password, BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await AuthService.login(email, password);

      if (result != null) {
        final userData = result['user'];

        if (userData is Map<String, dynamic>) {
          _user = UserModel.fromJson(userData);
        } else if (userData is UserModel) {
          _user = userData;
        }

        _token = result['token'] as String?;

        if (_token != null) {
          await SharedPrefs.saveToken(_token!);
        }

        _isLoading = false;
        notifyListeners();

        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
        return true;
      }
    } catch (e) {
      print('Login error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

    // ================== LOGIN DENGAN GOOGLE ==================
  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await AuthService.googleLogin();   // ← Pakai service (tidak duplikat)

      if (result != null) {
        final userData = result['user'];
        if (userData is Map<String, dynamic>) {
          _user = UserModel.fromJson(userData);
        } else if (userData is UserModel) {
          _user = userData;
        }
        _token = result['token'] as String?;
        if (_token != null) {
          await SharedPrefs.saveToken(_token!);
        }
        return true;
      }
    } catch (e) {
      print('Google login error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  // ================== LOGOUT ==================
  Future<void> logout() async {
    await SharedPrefs.removeToken();
    _token = null;
    _user = null;
    notifyListeners();
  }

  // Helper untuk save data (opsional, jika kamu punya method ini)
  Future<void> saveAuthData({required String token, required dynamic user}) async {
    _token = token;
    if (user is Map<String, dynamic>) {
      _user = UserModel.fromJson(user);
    } else if (user is UserModel) {
      _user = user;
    }
    await SharedPrefs.saveToken(token);
    notifyListeners();
  }
}