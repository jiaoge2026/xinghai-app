import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import 'storage_util.dart';

/// 网络错误类型枚举
enum NetworkErrorType {
  /// 连接超时
  connectTimeout,
  /// 接收数据超时
  receiveTimeout,
  /// 发送数据超时
  sendTimeout,
  /// 网络断开
  connectionError,
  /// 证书错误
  badCertificate,
  /// 取消请求
  cancel,
  /// 未知错误
  unknown,
  /// HTTP错误（非2xx）
  httpError,
  /// 服务器错误（5xx）
  serverError,
  /// 业务逻辑错误（code != 0）
  businessError,
}

/// 网络异常统一封装
class NetworkException implements Exception {
  final NetworkErrorType type;
  final String message;
  final int? statusCode;
  final dynamic data;

  NetworkException({
    required this.type,
    required this.message,
    this.statusCode,
    this.data,
  });

  /// 是否为401未授权错误
  bool get isUnauthorized => statusCode == 401;

  /// 是否为网络断开
  bool get isNetworkDisconnect =>
      type == NetworkErrorType.connectionError ||
      type == NetworkErrorType.connectTimeout;

  @override
  String toString() => 'NetworkException($type): $message';
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio _dio;

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      // 连接超时10秒（网络不好时快速失败）
      connectTimeout: const Duration(seconds: 10),
      // 接收超时30秒（大文件下载可调大）
      receiveTimeout: const Duration(seconds: 30),
      // 发送超时10秒
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageUtil.get(AppConstants.tokenKey);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // 直接传递原始错误，不做转换
        return handler.next(error);
      },
    ));
  }

  /// 将DioException转换为NetworkException
  NetworkException _convertDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return NetworkException(
          type: NetworkErrorType.connectTimeout,
          message: '连接超时，请检查网络',
        );
      case DioExceptionType.sendTimeout:
        return NetworkException(
          type: NetworkErrorType.sendTimeout,
          message: '发送请求超时',
        );
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          type: NetworkErrorType.receiveTimeout,
          message: '服务器响应超时，请稍后重试',
        );
      case DioExceptionType.connectionError:
        return NetworkException(
          type: NetworkErrorType.connectionError,
          message: '网络连接已断开，请检查网络',
        );
      case DioExceptionType.badCertificate:
        return NetworkException(
          type: NetworkErrorType.badCertificate,
          message: '证书验证失败',
        );
      case DioExceptionType.cancel:
        return NetworkException(
          type: NetworkErrorType.cancel,
          message: '请求已取消',
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          // Token过期，清除存储
          StorageUtil.remove(AppConstants.tokenKey);
          StorageUtil.remove(AppConstants.userKey);
          return NetworkException(
            type: NetworkErrorType.httpError,
            message: '登录已过期，请重新登录',
            statusCode: statusCode,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return NetworkException(
            type: NetworkErrorType.serverError,
            message: '服务器异常，请稍后重试',
            statusCode: statusCode,
            data: error.response?.data,
          );
        } else {
          return NetworkException(
            type: NetworkErrorType.httpError,
            message: _extractErrorMessage(error.response?.data) ?? '请求失败',
            statusCode: statusCode,
            data: error.response?.data,
          );
        }
      case DioExceptionType.unknown:
      default:
        return NetworkException(
          type: NetworkErrorType.unknown,
          message: error.message ?? '网络异常，请稍后重试',
        );
    }
  }

  /// 从响应数据中提取错误信息
  String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      return data['message'] ?? data['msg'] ?? data['error'];
    }
    return null;
  }

  Dio get dio => _dio;

  /// GET请求
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _convertDioError(e);
    }
  }

  /// POST请求
  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _convertDioError(e);
    }
  }

  /// PUT请求
  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw _convertDioError(e);
    }
  }

  /// DELETE请求
  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (e) {
      throw _convertDioError(e);
    }
  }
}
