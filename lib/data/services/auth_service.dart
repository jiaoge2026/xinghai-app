import '../../core/utils/api_client.dart';
import '../../core/utils/storage_util.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  Future<UserModel> login(String username, String password) async {
    print('[AuthService] login() called with username: $username');
    print('[AuthService] baseUrl: ${_client.dio.options.baseUrl}');
    print('[AuthService] full URL: ${_client.dio.options.baseUrl}/api/v1/auth/login');

    final resp = await _client.post('/api/v1/auth/login', data: {
      'username': username,
      'password': password,
    });

    print('[AuthService] login response received: code=${resp.data['code']}');

    final data = resp.data;
    if (data['code'] == 0 && data['data'] != null) {
      final token = data['data']['token'];
      final userData = data['data']['user'];

      await StorageUtil.set(AppConstants.tokenKey, token);
      await StorageUtil.set(AppConstants.userKey, jsonEncode(userData));

      return UserModel.fromJson(userData);
    } else {
      throw Exception(data['message'] ?? '登录失败');
    }
  }

  Future<void> logout() async {
    try {
      await _client.post('/api/v1/auth/logout');
    } catch (_) {
      // 忽略错误，确保本地清理
    }
    await StorageUtil.remove(AppConstants.tokenKey);
    await StorageUtil.remove(AppConstants.userKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await StorageUtil.get(AppConstants.tokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<UserModel?> getCurrentUser() async {
    final userStr = await StorageUtil.get(AppConstants.userKey);
    if (userStr != null && userStr.isNotEmpty) {
      final userData = jsonDecode(userStr);
      return UserModel.fromJson(userData);
    }
    return null;
  }
}
