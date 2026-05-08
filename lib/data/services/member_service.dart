import '../../core/utils/api_client.dart';
import '../models/member_model.dart';

class MemberService {
  final ApiClient _client = ApiClient();

  /// 会员注册
  /// 后端路径: POST /api/member/members/register
  Future<MemberModel> registerMember({
    required String phone,
    String? memberName,
    String? gender,
    String? birthday,
    String? email,
    String? idCard,
    String? address,
  }) async {
    final resp = await _client.post('/api/member/members/register', data: {
      'phone': phone,
      if (memberName != null) 'memberName': memberName,
      if (gender != null) 'gender': gender,
      if (birthday != null) 'birthday': birthday,
      if (email != null) 'email': email,
      if (idCard != null) 'idCard': idCard,
      if (address != null) 'address': address,
    });
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      return MemberModel.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? '会员注册失败');
  }

  /// 根据手机号查询会员
  /// 后端路径: GET /api/member/members/phone/{phone}
  Future<MemberModel?> getMemberByPhone(String phone) async {
    final resp = await _client.get('/api/member/members/phone/$phone');
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      return MemberModel.fromJson(data['data']);
    }
    if (data['code'] == 404) {
      return null;
    }
    throw Exception(data['message'] ?? '查询会员失败');
  }

  /// 获取会员详情
  /// 后端路径: GET /api/member/members/{id}
  Future<MemberModel> getMemberDetail(int id) async {
    final resp = await _client.get('/api/member/members/$id');
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      return MemberModel.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? '获取会员详情失败');
  }

  /// 获取积分明细
  /// 后端路径: GET /api/member/members/{id}/points
  Future<List<PointRecordModel>> getPointRecords(
    int memberId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };

    final resp = await _client.get('/api/member/members/$memberId/points', queryParameters: query);
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
      return list.map((e) => PointRecordModel.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? '获取积分明细失败');
  }

  /// 积分兑换
  /// 后端路径: POST /api/member/members/{id}/redeem
  Future<void> redeemPoints({
    required int memberId,
    required int points,
    String? orderId,
    String? remark,
  }) async {
    final resp = await _client.post('/api/member/members/$memberId/redeem', data: {
      'points': points,
      if (orderId != null) 'orderId': orderId,
      if (remark != null) 'remark': remark,
    });
    final data = resp.data;
    if (data['code'] != 0) {
      throw Exception(data['message'] ?? '积分兑换失败');
    }
  }

  /// 获取会员列表
  /// 后端路径: GET /api/member/members
  Future<List<MemberModel>> getMembers({
    String? keyword,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (keyword != null && keyword.isNotEmpty) query['keyword'] = keyword;

    final resp = await _client.get('/api/member/members', queryParameters: query);
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
      return list.map((e) => MemberModel.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? '获取会员列表失败');
  }
}
