import '../../core/utils/api_client.dart';
import '../models/attendance_model.dart';

class AttendanceService {
  final ApiClient _client = ApiClient();

  /// 分页查询考勤记录
  /// 后端路径: GET /api/hr/attendances
  Future<List<AttendanceModel>> getPage({
    String? startDate,
    String? endDate,
    int? employeeId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (startDate != null) query['startDate'] = startDate;
    if (endDate != null) query['endDate'] = endDate;
    if (employeeId != null) query['employeeId'] = employeeId;

    // 后端实际路径: /api/hr/attendances
    final resp = await _client.get('/api/hr/attendances', queryParameters: query);
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      // 后端返回格式兼容: 可能返回{data:{list:[],total:0}} 或 {data:[]}
      final dataBody = data['data'];
      List<dynamic> list;
      if (dataBody is Map) {
        list = dataBody['list'] as List<dynamic>? ?? [];
      } else if (dataBody is List) {
        list = dataBody;
      } else {
        list = [];
      }
      return list.map((e) => AttendanceModel.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? '获取考勤记录失败');
  }

  /// 打卡
  /// 后端路径: POST /api/hr/attendances
  /// 注意：后端可能需要先确认是否有独立的打卡接口
  Future<Map<String, dynamic>> clockIn() async {
    try {
      final resp = await _client.post('/api/hr/attendances/clock-in', data: {});
      final data = resp.data;

      if (data['code'] == 0 && data['data'] != null) {
        return data['data'];
      }
      throw Exception(data['message'] ?? '打卡失败');
    } catch (e) {
      // 如果后端无独立打卡接口，抛出异常提示
      throw Exception('打卡接口暂不可用，请联系管理员');
    }
  }

  /// 获取今日打卡状态
  /// 后端路径: GET /api/hr/attendances/today（如无则从列表中过滤）
  Future<AttendanceModel?> getTodayAttendance() async {
    try {
      final resp = await _client.get('/api/hr/attendances/today');
      final data = resp.data;

      if (data['code'] == 0 && data['data'] != null) {
        return AttendanceModel.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      // 后端如无此接口，返回null
      return null;
    }
  }

  /// 获取月度统计
  /// 后端路径: GET /api/hr/attendances/stats（如无则返回空）
  Future<AttendanceStatModel> getMonthlyStats(String month) async {
    try {
      final resp = await _client.get('/api/hr/attendances/stats', queryParameters: {
        'month': month,
      });
      final data = resp.data;

      if (data['code'] == 0 && data['data'] != null) {
        return AttendanceStatModel.fromJson(data['data']);
      }
      throw Exception(data['message'] ?? '获取月度统计失败');
    } catch (e) {
      // 后端如无此接口，返回空统计
      return AttendanceStatModel(
        presentDays: 0,
        lateDays: 0,
        absentDays: 0,
        leaveDays: 0,
        totalWorkHours: 0,
      );
    }
  }
}
