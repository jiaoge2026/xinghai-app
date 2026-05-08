import '../../core/utils/api_client.dart';
import '../models/delivery_order_model.dart';

class DeliveryService {
  final ApiClient _client = ApiClient();

  /// 获取配送单列表
  /// 后端路径: GET /api/logistics/delivery-orders
  Future<List<DeliveryOrderModel>> getDeliveryOrders({
    int? driverId,
    int? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (driverId != null) query['driverId'] = driverId;
    if (status != null) query['status'] = status;

    // 后端实际路径: /api/logistics/delivery-orders
    final resp = await _client.get('/api/logistics/delivery-orders', queryParameters: query);
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
      return list.map((e) => DeliveryOrderModel.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? '获取配送单列表失败');
  }

  /// 获取配送单详情
  /// 后端路径: GET /api/logistics/delivery-orders/{id}
  Future<DeliveryOrderModel> getDeliveryOrderDetail(int id) async {
    final resp = await _client.get('/api/logistics/delivery-orders/$id');
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      return DeliveryOrderModel.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? '获取配送单详情失败');
  }

  /// 更新配送状态
  /// 后端路径: PUT /api/logistics/delivery-orders/{id}/status
  Future<void> updateStatus(int id, int status, {String? remark}) async {
    final resp = await _client.put('/api/logistics/delivery-orders/$id/status', data: {
      'status': status,
      if (remark != null) 'remark': remark,
    });
    final data = resp.data;
    if (data['code'] != 0) {
      throw Exception(data['message'] ?? '更新状态失败');
    }
  }

  Future<void> confirmPickup(int id) async {
    await updateStatus(id, 2);
  }

  Future<void> startDelivery(int id) async {
    await updateStatus(id, 3);
  }

  Future<void> confirmArrival(int id) async {
    await updateStatus(id, 4);
  }

  /// 完成配送
  /// 后端路径: PUT /api/logistics/delivery-orders/{id}/complete
  Future<void> completeDelivery(int id, {
    String? recipientName,
    List<String>? photoUrls,
    String? remark,
  }) async {
    final resp = await _client.put('/api/logistics/delivery-orders/$id/complete', data: {
      if (recipientName != null) 'recipientName': recipientName,
      if (photoUrls != null) 'photoUrls': photoUrls,
      if (remark != null) 'remark': remark,
    });
    final data = resp.data;
    if (data['code'] != 0) {
      throw Exception(data['message'] ?? '完成配送失败');
    }
  }

  /// 上报司机位置
  /// 后端路径: POST /api/logistics/delivery-orders/driver/location
  Future<void> clockLocation(double lat, double lng) async {
    final resp = await _client.post('/api/logistics/delivery-orders/driver/location', data: {
      'locationLat': lat,
      'locationLng': lng,
    });
    final data = resp.data;
    if (data['code'] != 0) {
      throw Exception(data['message'] ?? '上报位置失败');
    }
  }
}
