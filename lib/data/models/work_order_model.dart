class WorkOrderModel {
  final int id;
  final String woNo;
  final int projectId;
  final String? projectNo;
  final int? engineerId;
  final String? engineerName;
  final int status;
  final int? customerId;
  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;
  final String? applianceType;
  final String? applianceBrand;
  final String? applianceModel;
  final String? faultDesc;
  final String? serviceType;
  final String? scheduledDate;
  final String? scheduledTimeSlot;
  final double? workHours;
  final double? travelFee;
  final double? materialFee;
  final String? remark;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<PartModel>? parts;

  WorkOrderModel({
    required this.id,
    required this.woNo,
    required this.projectId,
    this.projectNo,
    this.engineerId,
    this.engineerName,
    required this.status,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.applianceType,
    this.applianceBrand,
    this.applianceModel,
    this.faultDesc,
    this.serviceType,
    this.scheduledDate,
    this.scheduledTimeSlot,
    this.workHours,
    this.travelFee,
    this.materialFee,
    this.remark,
    this.createdAt,
    this.updatedAt,
    this.parts,
  });

  factory WorkOrderModel.fromJson(Map<String, dynamic> json) {
    return WorkOrderModel(
      id: json['id'] ?? 0,
      woNo: json['woNo'] ?? '',
      projectId: json['projectId'] ?? 0,
      projectNo: json['projectNo'],
      engineerId: json['assignedEngineerId'] ?? json['engineerId'],
      engineerName: json['assignedEngineerName'] ?? json['engineerName'],
      status: json['status'] ?? 1,
      customerId: json['customerId'],
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      customerAddress: json['customerAddress'],
      applianceType: json['applianceType'],
      applianceBrand: json['applianceBrand'],
      applianceModel: json['applianceModel'],
      faultDesc: json['faultDesc'],
      serviceType: json['serviceType'],
      scheduledDate: json['scheduledDate'],
      scheduledTimeSlot: json['scheduledTimeSlot'],
      workHours: json['workHours']?.toDouble(),
      travelFee: json['travelFee']?.toDouble(),
      materialFee: json['materialFee']?.toDouble(),
      remark: json['remark'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      parts: (json['parts'] as List<dynamic>?)?.map((e) => PartModel.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'woNo': woNo,
      'projectId': projectId,
      'projectNo': projectNo,
      'engineerId': engineerId,
      'engineerName': engineerName,
      'status': status,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'applianceType': applianceType,
      'applianceBrand': applianceBrand,
      'applianceModel': applianceModel,
      'faultDesc': faultDesc,
      'serviceType': serviceType,
      'scheduledDate': scheduledDate,
      'scheduledTimeSlot': scheduledTimeSlot,
      'workHours': workHours,
      'travelFee': travelFee,
      'materialFee': materialFee,
      'remark': remark,
    };
  }

  WorkOrderModel copyWith({
    int? id, String? woNo, int? projectId, String? projectNo,
    int? engineerId, String? engineerName, int? status,
    int? customerId, String? customerName, String? customerPhone,
    String? customerAddress, String? applianceType, String? applianceBrand,
    String? applianceModel, String? faultDesc, String? serviceType,
    String? scheduledDate, String? scheduledTimeSlot,
    double? workHours, double? travelFee, double? materialFee,
    String? remark, DateTime? createdAt, DateTime? updatedAt,
    List<PartModel>? parts,
  }) {
    return WorkOrderModel(
      id: id ?? this.id,
      woNo: woNo ?? this.woNo,
      projectId: projectId ?? this.projectId,
      projectNo: projectNo ?? this.projectNo,
      engineerId: engineerId ?? this.engineerId,
      engineerName: engineerName ?? this.engineerName,
      status: status ?? this.status,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      applianceType: applianceType ?? this.applianceType,
      applianceBrand: applianceBrand ?? this.applianceBrand,
      applianceModel: applianceModel ?? this.applianceModel,
      faultDesc: faultDesc ?? this.faultDesc,
      serviceType: serviceType ?? this.serviceType,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTimeSlot: scheduledTimeSlot ?? this.scheduledTimeSlot,
      workHours: workHours ?? this.workHours,
      travelFee: travelFee ?? this.travelFee,
      materialFee: materialFee ?? this.materialFee,
      remark: remark ?? this.remark,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parts: parts ?? this.parts,
    );
  }
}

class PartModel {
  final int id;
  final String? partNo;
  final String name;
  final String? spec;
  final double? unitPrice;
  final int quantity;

  PartModel({
    required this.id,
    this.partNo,
    required this.name,
    this.spec,
    this.unitPrice,
    this.quantity = 1,
  });

  factory PartModel.fromJson(Map<String, dynamic> json) {
    return PartModel(
      id: json['id'] ?? 0,
      partNo: json['partNo'],
      name: json['name'] ?? '',
      spec: json['spec'],
      unitPrice: json['unitPrice']?.toDouble(),
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'partId': id,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }
}
