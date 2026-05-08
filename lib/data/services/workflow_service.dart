import '../../core/utils/api_client.dart';
import '../models/workflow_model.dart';

class WorkflowService {
  final ApiClient _client = ApiClient();

  /// 获取待审批列表
  /// 后端路径: GET /api/workflow/pending
  Future<List<WorkflowInstanceModel>> getPendingApprovals({
    int page = 1,
    int pageSize = 20,
  }) async {
    final resp = await _client.get('/api/workflow/pending', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });
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
      return list.map((e) => WorkflowInstanceModel.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? '获取待审批列表失败');
  }

  /// 获取我的申请列表
  /// 后端路径: GET /api/workflow/my-applications
  Future<List<WorkflowInstanceModel>> getMyApplications({
    int page = 1,
    int pageSize = 20,
    int? status,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (status != null) query['status'] = status;

    final resp = await _client.get('/api/workflow/my-applications', queryParameters: query);
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
      return list.map((e) => WorkflowInstanceModel.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? '获取我的申请列表失败');
  }

  /// 获取审批详情
  /// 后端路径: GET /api/workflow/instances/{instanceNo}
  Future<WorkflowDetailModel> getInstanceDetail(String instanceNo) async {
    final resp = await _client.get('/api/workflow/instances/$instanceNo');
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      return WorkflowDetailModel.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? '获取审批详情失败');
  }

  /// 启动审批流程
  /// 后端路径: POST /api/workflow/start
  Future<String> startWorkflow({
    required String workflowCode,
    required String businessType,
    required int businessId,
    required Map<String, dynamic> formData,
  }) async {
    final resp = await _client.post('/api/workflow/start', data: {
      'workflowCode': workflowCode,
      'businessType': businessType,
      'businessId': businessId,
      'formData': formData,
    });
    final resData = resp.data;

    if (resData['code'] == 0 && resData['data'] != null) {
      return resData['data']['instanceNo'] ?? '';
    }
    throw Exception(resData['message'] ?? '启动审批流程失败');
  }

  /// 审批通过
  /// 后端路径: POST /api/workflow/approve
  Future<void> approve({
    required String instanceId,
    String? comment,
  }) async {
    final resp = await _client.post('/api/workflow/approve', data: {
      'instanceId': instanceId,
      if (comment != null) 'comment': comment,
    });
    final data = resp.data;

    if (data['code'] != 0) {
      throw Exception(data['message'] ?? '审批通过失败');
    }
  }

  /// 审批驳回
  /// 后端路径: POST /api/workflow/reject
  Future<void> reject({
    required String instanceId,
    required String comment,
  }) async {
    final resp = await _client.post('/api/workflow/reject', data: {
      'instanceId': instanceId,
      'comment': comment,
    });
    final data = resp.data;

    if (data['code'] != 0) {
      throw Exception(data['message'] ?? '审批驳回失败');
    }
  }

  /// 撤回申请
  /// 后端路径: POST /api/workflow/cancel
  Future<void> cancel(String instanceId) async {
    final resp = await _client.post('/api/workflow/cancel', data: {
      'instanceId': instanceId,
    });
    final data = resp.data;

    if (data['code'] != 0) {
      throw Exception(data['message'] ?? '撤回失败');
    }
  }

  /// 获取流程定义列表
  /// 后端路径: GET /api/workflow/definitions
  Future<List<WorkflowDefinitionModel>> getDefinitions() async {
    final resp = await _client.get('/api/workflow/definitions');
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      final list = data['data'] as List<dynamic>? ?? [];
      return list.map((e) => WorkflowDefinitionModel.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? '获取流程定义列表失败');
  }

  /// 获取待审批数量
  /// 后端路径: GET /api/workflow/pending/count
  Future<int> getPendingCount() async {
    try {
      final resp = await _client.get('/api/workflow/pending/count');
      final data = resp.data;

      if (data['code'] == 0 && data['data'] != null) {
        return data['data']['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}
