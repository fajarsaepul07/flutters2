import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/app_constants.dart';

class ApiService {
  static Future<http.Response> post(
    String endpoint, 
    Map<String, dynamic> body, 
    {String? token}
  ) async {
    final url = Uri.parse(AppConstants.baseUrl + endpoint);

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    
    return await http.post(url, headers: headers, body: jsonEncode(body));
  }

  // Tambahan: Method GET (ini yang dibutuhkan oleh _fetchHomeData)
  static Future<http.Response> get(
    String endpoint, 
    {String? token}
  ) async {
    final url = Uri.parse(AppConstants.baseUrl + endpoint);

    final headers = {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    
    return await http.get(url, headers: headers);
  }
}