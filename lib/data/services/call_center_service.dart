import '../../core/utils/api_client.dart';
import '../models/call_record_model.dart';

class CallCenterService {
  final ApiClient _client = ApiClient();

  /// 获取来电记录
  /// 后端路径: GET /api/callcenter/call-records
  Future<List<CallRecordModel>> getCallRecords({
    int? status,
    int? employeeId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (status != null) query['status'] = status;
    if (employeeId != null) query['employeeId'] = employeeId;

    final resp = await _client.get('/api/callcenter/call-records', queryParameters: query);
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      final dataBody = data['data'];
      List<dynamic> list;
      if (dataBody is Map) {
        list = dataBody['list'] as List<dynamic>? ?? [];
      } else if (dataBody is List) {
        list = dataBody;
      } else {
        list = [];
      }
      return list.map((e) => CallRecordModel.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? '获取来电记录失败');
  }

  /// 获取来电详情
  /// 后端路径: GET /api/callcenter/call-records/{id}
  Future<CallRecordModel> getCallRecordDetail(int id) async {
    final resp = await _client.get('/api/callcenter/call-records/$id');
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      return CallRecordModel.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? '获取来电详情失败');
  }

  /// 处理来电记录
  /// 后端路径: PUT /api/callcenter/call-records/{id}/process
  Future<void> processCallRecord({
    required int id,
    String? remark,
    String? associatedType,
    int? associatedId,
  }) async {
    final resp = await _client.put('/api/callcenter/call-records/$id/process', data: {
      if (remark != null) 'processRemark': remark,
      if (associatedType != null) 'associatedType': associatedType,
      if (associatedId != null) 'associatedId': associatedId,
    });
    final data = resp.data;
    if (data['code'] != 0) {
      throw Exception(data['message'] ?? '处理失败');
    }
  }

  /// 获取回拨请求列表
  /// 后端路径: GET /api/callcenter/callback-requests
  Future<List<CallbackRequestModel>> getCallbackRequests({
    int? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (status != null) query['status'] = status;

    final resp = await _client.get('/api/callcenter/callback-requests', queryParameters: query);
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      final dataBody = data['data'];
      List<dynamic> list;
      if (dataBody is Map) {
        list = dataBody['list'] as List<dynamic>? ?? [];
      } else if (dataBody is List) {
        list = dataBody;
      } else {
        list = [];
      }
      return list.map((e) => CallbackRequestModel.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? '获取回拨请求失败');
  }

  /// 创建回拨请求
  /// 后端路径: POST /api/callcenter/callback-requests
  Future<int> createCallbackRequest(Map<String, dynamic> requestData) async {
    final resp = await _client.post('/api/callcenter/callback-requests', data: requestData);
    final result = resp.data;
    if (result['code'] == 0) {
      return result['data']['id'] ?? 0;
    }
    throw Exception(result['message'] ?? '创建回拨请求失败');
  }
}
