import '../../core/utils/api_client.dart';
import '../models/leave_model.dart';

class LeaveService {
  final ApiClient _client = ApiClient();

  /// 查询请假记录（分页）
  /// 后端路径: GET /api/hr/leave
  Future<List<LeaveModel>> getPage({
    int? employeeId,
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (employeeId != null) query['employeeId'] = employeeId;
    if (status != null && status.isNotEmpty) query['status'] = status;

    // 后端实际路径: /api/hr/leave（无s，单数）
    final resp = await _client.get('/api/hr/leave', queryParameters: query);
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      final list = data['data']['list'] as List<dynamic>? ?? [];
      return list.map((e) => LeaveModel.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? '获取请假记录失败');
  }

  /// 申请请假
  /// 后端路径: POST /api/hr/leave
  /// 注意：后端要求 employeeId 字段，前端需要先获取当前登录员工信息
  Future<void> apply({
    required int employeeId,
    required String leaveType,
    required String startDate,
    required String endDate,
    required double totalDays,
    required String reason,
  }) async {
    final resp = await _client.post('/api/hr/leave', data: {
      'employeeId': employeeId,
      'leaveType': leaveType,
      'startDate': startDate,
      'endDate': endDate,
      'totalDays': totalDays,
      'reason': reason,
    });
    final resData = resp.data;
    if (resData['code'] != 0) {
      throw Exception(resData['message'] ?? '申请请假失败');
    }
  }

  /// 获取剩余假期
  /// 后端路径: GET /api/hr/leave/balance（如后端无此接口则返回空模型）
  Future<LeaveBalanceModel> getLeaveBalance() async {
    try {
      final resp = await _client.get('/api/hr/leave/balance');
      final data = resp.data;

      if (data['code'] == 0 && data['data'] != null) {
        return LeaveBalanceModel.fromJson(data['data']);
      }
      throw Exception(data['message'] ?? '获取假期余额失败');
    } catch (e) {
      // 后端如无余额接口，返回空模型
      return LeaveBalanceModel(
        annualBalance: 0,
        sickBalance: 0,
        personalBalance: 0,
      );
    }
  }
}
