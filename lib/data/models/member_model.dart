class MemberModel {
  final int id;
  final String? memberNo;
  final String? memberName;
  final String? phone;
  final String? gender;
  final String? birthday;
  final String? email;
  final String? memberLevel;
  final int? totalPoints;
  final int? availablePoints;
  final double? totalConsume;
  final String? registerDate;
  final String? expireDate;
  final int? status;
  final String? storeName;
  final String? idCard;
  final String? address;

  MemberModel({
    required this.id,
    this.memberNo,
    this.memberName,
    this.phone,
    this.gender,
    this.birthday,
    this.email,
    this.memberLevel,
    this.totalPoints,
    this.availablePoints,
    this.totalConsume,
    this.registerDate,
    this.expireDate,
    this.status,
    this.storeName,
    this.idCard,
    this.address,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id'] ?? 0,
      memberNo: json['memberNo'],
      memberName: json['memberName'],
      phone: json['phone'],
      gender: json['gender'],
      birthday: json['birthday'],
      email: json['email'],
      memberLevel: json['memberLevel'],
      totalPoints: json['totalPoints'],
      availablePoints: json['availablePoints'],
      totalConsume: json['totalConsume']?.toDouble(),
      registerDate: json['registerDate'],
      expireDate: json['expireDate'],
      status: json['status'],
      storeName: json['storeName'],
      idCard: json['idCard'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'memberNo': memberNo,
      'memberName': memberName,
      'phone': phone,
      'gender': gender,
      'birthday': birthday,
      'email': email,
      'memberLevel': memberLevel,
      'totalPoints': totalPoints,
      'availablePoints': availablePoints,
      'totalConsume': totalConsume,
      'registerDate': registerDate,
      'expireDate': expireDate,
      'status': status,
      'storeName': storeName,
      'idCard': idCard,
      'address': address,
    };
  }

  String get statusText {
    switch (status) {
      case 1:
        return '正常';
      case 2:
        return '暂停';
      case 3:
        return '注销';
      default:
        return '未知';
    }
  }

  String get genderText {
    switch (gender) {
      case 'male':
        return '男';
      case 'female':
        return '女';
      default:
        return '未知';
    }
  }
}

class PointRecordModel {
  final int id;
  final int memberId;
  final String? memberName;
  final int points;
  final int type;
  final String? source;
  final String? orderNo;
  final String? remark;
  final DateTime? createdAt;

  PointRecordModel({
    required this.id,
    required this.memberId,
    this.memberName,
    required this.points,
    required this.type,
    this.source,
    this.orderNo,
    this.remark,
    this.createdAt,
  });

  factory PointRecordModel.fromJson(Map<String, dynamic> json) {
    return PointRecordModel(
      id: json['id'] ?? 0,
      memberId: json['memberId'] ?? 0,
      memberName: json['memberName'],
      points: json['points'] ?? 0,
      type: json['type'] ?? 1,
      source: json['source'],
      orderNo: json['orderNo'],
      remark: json['remark'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  String get typeText {
    switch (type) {
      case 1:
        return '获得';
      case 2:
        return '兑换';
      case 3:
        return '过期';
      default:
        return '未知';
    }
  }
}
