
import 'package:flutter/material.dart';

import '../../../screens/home_screen.dart';
import '../data/models/user_model.dart';
import '../services/auth_service.dart';
import '../../../core/utils/shared_prefs.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  String? _token;
  bool _isLoading = false;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null;

  // Login biasa (tidak diubah)
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
        } else {
          _user = UserModel.fromJson(userData as Map<String, dynamic>);
        }

        _token = result['token'] as String?;

        if (_token != null) {
          await SharedPrefs.saveToken(_token!);
        }

        _isLoading = false;
        notifyListeners();

        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
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

  // LOGIN GOOGLE BARU (sama seperti Laravel)
  Future<bool> googleLogin(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await AuthService.googleLogin();

      if (result != null) {
        final userData = result['user'];

        if (userData is Map<String, dynamic>) {
          _user = UserModel.fromJson(userData);
        } else if (userData is UserModel) {
          _user = userData;
        } else {
          _user = UserModel.fromJson(userData as Map<String, dynamic>);
        }

        _token = result['token'] as String?;

        if (_token != null) {
          await SharedPrefs.saveToken(_token!);
        }

        _isLoading = false;
        notifyListeners();

        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
        return true;
      }
    } catch (e) {
      print('Google login error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await SharedPrefs.removeToken();
    _token = null;
    _user = null;
    notifyListeners();
  }
}