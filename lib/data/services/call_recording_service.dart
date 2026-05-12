import 'dart:io';
import 'package:dio/dio.dart';

/// 通话录音服务 - 封装原生Android录音模块
///
/// 调用流程：
/// 1. App启动 → MainActivity启动CallRecordingService（前台服务）
/// 2. 来电 → CallStateReceiver监听PHONE_STATE → 通话接通后自动开始录音
/// 3. 通话结束 → CallStateReceiver检测IDLE → 自动停止录音
/// 4. 录音停止后 → 自动上传到服务器 /api/fsm/recordings/upload
/// 5. 上传成功 → 保存到tb_call_recording表
class CallRecordingService {
  static const _channelName = 'com.xinghai.erp/call_recording';
  // Platform channel在Flutter端通过NativeFlutterApi调用，这里用HTTP模拟
  // 实际录音逻辑在原生Android代码中执行

  static const String _apiBase = 'http://47.103.11.151:38080/api/fsm';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
  ));

  /// 存储登录信息到本地（供原生服务上传时使用）
  Future<void> saveAuthInfo({
    required int engineerId,
    required String engineerName,
    required String token,
  }) async {
    // 通过platform channel通知原生服务保存认证信息
    // TODO: 实现Flutter端platform channel调用
  }

  /// 获取本地录音文件列表
  Future<List<Map<String, dynamic>>> getLocalRecordings() async {
    try {
      final response = await _dio.get('$_apiBase/recordings/local');
      if (response.data['code'] == 0) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// 获取服务器端录音列表
  Future<List<Map<String, dynamic>>> getServerRecordings(int engineerId) async {
    try {
      final response = await _dio.get(
        '$_apiBase/recordings',
        queryParameters: {'engineerId': engineerId},
      );
      if (response.data['code'] == 0) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// 上传录音文件到服务器
  Future<Map<String, dynamic>?> uploadRecording({
    required String filePath,
    required int engineerId,
    required String engineerName,
    String? phoneNumber,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return {'success': false, 'error': 'File not found'};
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: file.path.split('/').last),
        'engineerId': engineerId,
        'engineerName': engineerName,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
      });

      final response = await _dio.post(
        '$_apiBase/recordings/upload',
        data: formData,
        onSendProgress: (sent, total) {
          // 上传进度
        },
      );

      if (response.data['code'] == 0) {
        return {'success': true, 'data': response.data['data']};
      } else {
        return {'success': false, 'error': response.data['message']};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 删除本地录音文件
  Future<bool> deleteLocalRecording(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 获取录音文件访问URL
  String getRecordingUrl(String fileId) {
    return '$_apiBase/recordings/$fileId/play';
  }

  /// 获取录音文件时长（秒）
  int getDurationFromFileName(String fileName) {
    // 从文件名解析录制时间
    // 格式：CALL_yyyyMMdd_HHmmss_phone.m4a
    return 0;
  }
}
