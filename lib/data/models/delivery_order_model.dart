class DeliveryOrderModel {
  final int id;
  final String deliveryNo;
  final int workOrderId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String? contactName;
  final int? driverId;
  final String? pickupTime;
  final int status;
  final double totalQuantity;
  final double totalWeight;
  final String? recipientName;
  final List<String>? photoUrls;
  final String? remark;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DeliveryOrderModel({
    required this.id,
    required this.deliveryNo,
    required this.workOrderId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    this.contactName,
    this.driverId,
    this.pickupTime,
    required this.status,
    required this.totalQuantity,
    required this.totalWeight,
    this.recipientName,
    this.photoUrls,
    this.remark,
    this.createdAt,
    this.updatedAt,
  });

  factory DeliveryOrderModel.fromJson(Map<String, dynamic> json) {
    return DeliveryOrderModel(
      id: json['id'] ?? 0,
      deliveryNo: json['deliveryNo'] ?? '',
      workOrderId: json['workOrderId'] ?? 0,
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      customerAddress: json['customerAddress'] ?? '',
      contactName: json['contactName'],
      driverId: json['driverId'],
      pickupTime: json['pickupTime'],
      status: json['status'] ?? 1,
      totalQuantity: (json['totalQuantity'] ?? 0).toDouble(),
      totalWeight: (json['totalWeight'] ?? 0).toDouble(),
      recipientName: json['recipientName'],
      photoUrls: (json['photoUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      remark: json['remark'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deliveryNo': deliveryNo,
      'workOrderId': workOrderId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'contactName': contactName,
      'driverId': driverId,
      'pickupTime': pickupTime,
      'status': status,
      'totalQuantity': totalQuantity,
      'totalWeight': totalWeight,
      'recipientName': recipientName,
      'photoUrls': photoUrls,
      'remark': remark,
    };
  }

  DeliveryOrderModel copyWith({
    int? id,
    String? deliveryNo,
    int? workOrderId,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    String? contactName,
    int? driverId,
    String? pickupTime,
    int? status,
    double? totalQuantity,
    double? totalWeight,
    String? recipientName,
    List<String>? photoUrls,
    String? remark,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeliveryOrderModel(
      id: id ?? this.id,
      deliveryNo: deliveryNo ?? this.deliveryNo,
      workOrderId: workOrderId ?? this.workOrderId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      contactName: contactName ?? this.contactName,
      driverId: driverId ?? this.driverId,
      pickupTime: pickupTime ?? this.pickupTime,
      status: status ?? this.status,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      totalWeight: totalWeight ?? this.totalWeight,
      recipientName: recipientName ?? this.recipientName,
      photoUrls: photoUrls ?? this.photoUrls,
      remark: remark ?? this.remark,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get statusText {
    switch (status) {
      case 1:
        return '待取货';
      case 2:
        return '已取货';
      case 3:
        return '配送中';
      case 4:
        return '已到达';
      case 5:
        return '已完成';
      case 6:
        return '异常';
      default:
        return '未知';
    }
  }
}

class DriverModel {
  final int id;
  final String driverName;
  final String phone;
  final String? vehicleNo;
  final String? vehicleType;
  final double? capacity;
  final int status;
  final double? locationLat;
  final double? locationLng;

  DriverModel({
    required this.id,
    required this.driverName,
    required this.phone,
    this.vehicleNo,
    this.vehicleType,
    this.capacity,
    required this.status,
    this.locationLat,
    this.locationLng,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'] ?? 0,
      driverName: json['driverName'] ?? '',
      phone: json['phone'] ?? '',
      vehicleNo: json['vehicleNo'],
      vehicleType: json['vehicleType'],
      capacity: json['capacity']?.toDouble(),
      status: json['status'] ?? 1,
      locationLat: json['locationLat']?.toDouble(),
      locationLng: json['locationLng']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverName': driverName,
      'phone': phone,
      'vehicleNo': vehicleNo,
      'vehicleType': vehicleType,
      'capacity': capacity,
      'status': status,
      'locationLat': locationLat,
      'locationLng': locationLng,
    };
  }
}
