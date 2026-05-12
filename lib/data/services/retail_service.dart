import '../../core/utils/api_client.dart';
import '../models/product_model.dart';
import '../models/sales_order_model.dart';

class RetailService {
  final ApiClient _client = ApiClient();

  /// 获取商品列表
  /// 后端路径: GET /api/retail/products
  Future<List<ProductModel>> getProducts({
    String? category,
    String? brand,
    String? keyword,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (brand != null && brand.isNotEmpty) query['brand'] = brand;
    if (keyword != null && keyword.isNotEmpty) query['keyword'] = keyword;

    final resp = await _client.get('/api/v1/retail/products', queryParameters: query);
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
      return list.map((e) => ProductModel.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? '获取商品列表失败');
  }

  /// 获取商品详情
  /// 后端路径: GET /api/retail/products/{id}
  Future<ProductModel> getProductDetail(int id) async {
    final resp = await _client.get('/api/v1/retail/products/$id');
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      return ProductModel.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? '获取商品详情失败');
  }

  /// 创建销售订单
  /// 后端路径: POST /api/retail/orders
  Future<SalesOrderModel> createSalesOrder({
    required List<CartItemModel> items,
    int? customerId,
    String? customerName,
    String? customerPhone,
    double? discountAmount,
    String? paymentMethod,
    String? couponId,
    String? remark,
  }) async {
    final resp = await _client.post('/api/v1/retail/orders', data: {
      'items': items.map((e) => e.toJson()).toList(),
      if (customerId != null) 'customerId': customerId,
      if (customerName != null) 'customerName': customerName,
      if (customerPhone != null) 'customerPhone': customerPhone,
      if (discountAmount != null) 'discountAmount': discountAmount,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (couponId != null) 'couponId': couponId,
      if (remark != null) 'remark': remark,
    });
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      return SalesOrderModel.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? '创建订单失败');
  }

  /// 获取订单列表
  /// 后端路径: GET /api/retail/orders
  Future<List<SalesOrderModel>> getOrders({
    int? status,
    int? storeId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (status != null) query['status'] = status;
    if (storeId != null) query['storeId'] = storeId;

    final resp = await _client.get('/api/v1/retail/orders', queryParameters: query);
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
      return list.map((e) => SalesOrderModel.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? '获取订单列表失败');
  }

  /// 获取订单详情
  /// 后端路径: GET /api/retail/orders/{id}
  Future<SalesOrderModel> getOrderDetail(int id) async {
    final resp = await _client.get('/api/v1/retail/orders/$id');
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      return SalesOrderModel.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? '获取订单详情失败');
  }

  /// 支付订单
  /// 后端路径: POST /api/retail/orders/{id}/pay
  Future<void> payOrder(int id, String paymentMethod) async {
    final resp = await _client.post('/api/v1/retail/orders/$id/pay', data: {
      'paymentMethod': paymentMethod,
    });
    final data = resp.data;
    if (data['code'] != 0) {
      throw Exception(data['message'] ?? '支付失败');
    }
  }

  /// 退款订单
  /// 后端路径: POST /api/retail/orders/{id}/refund
  Future<void> refundOrder(int id, {double? amount}) async {
    final resp = await _client.post('/api/v1/retail/orders/$id/refund', data: {
      if (amount != null) 'amount': amount,
    });
    final data = resp.data;
    if (data['code'] != 0) {
      throw Exception(data['message'] ?? '退款失败');
    }
  }

  /// 获取销售统计（后端可能无此接口，返回空map）
  /// 后端路径: GET /api/retail/sales-stats（如不存在则返回空）
  Future<Map<String, dynamic>> getSalesStats({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (startDate != null) query['startDate'] = startDate;
      if (endDate != null) query['endDate'] = endDate;

      final resp = await _client.get('/api/v1/retail/sales-stats', queryParameters: query);
      final data = resp.data;

      if (data['code'] == 0 && data['data'] != null) {
        return data['data'];
      }
      throw Exception(data['message'] ?? '获取销售统计失败');
    } catch (e) {
      // 后端如无此接口，返回空map
      return {};
    }
  }

  /// 获取门店库存
  /// 后端路径: GET /api/retail/stores/{storeId}/inventory
  Future<List<ProductModel>> getStoreInventory(int storeId) async {
    final resp = await _client.get('/api/v1/retail/stores/$storeId/inventory');
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      final list = data['data'] as List<dynamic>? ?? [];
      return list.map((e) => ProductModel.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? '获取门店库存失败');
  }

  /// 获取商品分类列表
  /// 后端路径: GET /api/retail/products/categories（返回tb_product.category的DISTINCT值）
  Future<List<String>> getCategories() async {
    final resp = await _client.get('/api/v1/retail/products/categories');
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      final list = data['data'] as List<dynamic>? ?? [];
      return list.map((e) => e.toString()).toList();
    }
    throw Exception(data['message'] ?? '获取分类失败');
  }

  /// 获取品牌列表
  /// 后端路径: GET /api/retail/products/brands
  Future<List<String>> getBrands() async {
    final resp = await _client.get('/api/v1/retail/products/brands');
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      final list = data['data'] as List<dynamic>? ?? [];
      return list.map((e) => e.toString()).toList();
    }
    throw Exception(data['message'] ?? '获取品牌失败');
  }
}
