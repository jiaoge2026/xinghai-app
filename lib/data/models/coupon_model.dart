class CouponModel {
  final int id;
  final String? couponName;
  final String? couponType;
  final double? discountAmount;
  final double? minConsume;
  final String? validFrom;
  final String? validTo;
  final int? status;
  final int? usedCount;
  final int? totalCount;
  final int? memberId;
  final String? description;
  final DateTime? createdAt;

  CouponModel({
    required this.id,
    this.couponName,
    this.couponType,
    this.discountAmount,
    this.minConsume,
    this.validFrom,
    this.validTo,
    this.status,
    this.usedCount,
    this.totalCount,
    this.memberId,
    this.description,
    this.createdAt,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id'] ?? 0,
      couponName: json['couponName'],
      couponType: json['couponType'],
      discountAmount: json['discountAmount']?.toDouble(),
      minConsume: json['minConsume']?.toDouble(),
      validFrom: json['validFrom'],
      validTo: json['validTo'],
      status: json['status'],
      usedCount: json['usedCount'],
      totalCount: json['totalCount'],
      memberId: json['memberId'],
      description: json['description'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'couponName': couponName,
      'couponType': couponType,
      'discountAmount': discountAmount,
      'minConsume': minConsume,
      'validFrom': validFrom,
      'validTo': validTo,
      'status': status,
      'usedCount': usedCount,
      'totalCount': totalCount,
      'memberId': memberId,
      'description': description,
    };
  }

  String get statusText {
    switch (status) {
      case 1:
        return '可用';
      case 2:
        return '已使用';
      case 3:
        return '已过期';
      default:
        return '未知';
    }
  }

  String get couponTypeText {
    switch (couponType) {
      case 'cash':
        return '代金券';
      case 'discount':
        return '折扣券';
      case 'gift':
        return '礼品券';
      default:
        return couponType ?? '未知';
    }
  }

  bool get isExpired {
    if (validTo == null) return false;
    return DateTime.now().isAfter(DateTime.parse(validTo!));
  }

  bool get isAvailable => status == 1 && !isExpired;
}
