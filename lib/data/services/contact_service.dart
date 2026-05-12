import '../../core/utils/api_client.dart';

class ContactModel {
  final int id;
  final int customerId;
  final String contactName;
  final String? phone;
  final String? position;
  final int isPrimary;

  ContactModel({
    required this.id,
    required this.customerId,
    required this.contactName,
    this.phone,
    this.position,
    required this.isPrimary,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] ?? 0,
      customerId: json['customerId'] ?? 0,
      contactName: json['contactName'] ?? '',
      phone: json['phone'],
      position: json['position'],
      isPrimary: json['isPrimary'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'contactName': contactName,
      'phone': phone,
      'position': position,
      'isPrimary': isPrimary,
    };
  }
}

class ContactService {
  final ApiClient _client = ApiClient();

  /// 获取联系人列表
  /// 后端路径: GET /api/crm/contacts?customerId=xxx
  Future<List<ContactModel>> getContacts(int customerId) async {
    final resp = await _client.get('/api/v1/crm/contacts', queryParameters: {
      'customerId': customerId,
    });
    final data = resp.data;

    if (data['code'] == 0 && data['data'] != null) {
      final list = data['data'] as List<dynamic>? ?? [];
      return list.map((e) => ContactModel.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? '获取联系人列表失败');
  }

  /// 新增联系人
  /// 后端路径: POST /api/crm/contacts
  Future<int> addContact(Map<String, dynamic> contactData) async {
    final resp = await _client.post('/api/v1/crm/contacts', data: contactData);
    final result = resp.data;
    if (result['code'] == 0) {
      return result['data']['id'] ?? 0;
    }
    throw Exception(result['message'] ?? '新增联系人失败');
  }

  /// 设为主联系人
  /// 后端路径: PUT /api/crm/contacts/{id}/primary
  Future<void> setPrimary(int id) async {
    final resp = await _client.put('/api/v1/crm/contacts/$id/primary');
    final data = resp.data;
    if (data['code'] != 0) {
      throw Exception(data['message'] ?? '设为主联系人失败');
    }
  }
}
