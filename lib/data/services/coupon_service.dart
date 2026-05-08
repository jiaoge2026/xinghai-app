import '../../core/utils/api_client.dart';
import '../models/coupon_model.dart';

class CouponService {
  final ApiClient _client = ApiClient();

  Future<List<CouponModel>> getAvailableCoupons(int memberId) async {
    final resp = await _client.get('/api/member/members/$memberId/coupons', queryParameters: {
      'status': 1,
    });
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      final list = data['data'] as List<dynamic>? ?? [];
      return list.map((e) => CouponModel.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? '获取可用优惠券失败');
  }

  Future<List<CouponModel>> getMemberCoupons(
    int memberId, {
    int? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (status != null) query['status'] = status;

    final resp = await _client.get('/api/member/members/$memberId/coupons', queryParameters: query);
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      final list = data['data']['list'] as List<dynamic>? ?? [];
      return list.map((e) => CouponModel.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? '获取会员优惠券失败');
  }

  Future<void> receiveCoupon(int couponId, int memberId) async {
    final resp = await _client.post('/api/member/coupons/$couponId/receive', data: {
      'memberId': memberId,
    });
    final data = resp.data;
    if (data['code'] != 0) {
      throw Exception(data['message'] ?? '领券失败');
    }
  }

  Future<List<CouponModel>> getCouponTemplates({
    int page = 1,
    int pageSize = 20,
  }) async {
    final resp = await _client.get('/api/member/coupon-templates', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      final list = data['data']['list'] as List<dynamic>? ?? [];
      return list.map((e) => CouponModel.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? '获取优惠券模板失败');
  }
}
