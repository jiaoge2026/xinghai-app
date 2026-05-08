class ProjectModel {
  final int id;
  final String projectNo;
  final String name;
  final int? customerId;
  final String? customerName;
  final double? contractAmount;
  final int status;
  final String? signDate;
  final String? startDate;
  final String? endDate;
  final String? descText;
  final int? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? workOrderCount;
  final double? totalCost;

  ProjectModel({
    required this.id,
    required this.projectNo,
    required this.name,
    this.customerId,
    this.customerName,
    this.contractAmount,
    required this.status,
    this.signDate,
    this.startDate,
    this.endDate,
    this.descText,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.workOrderCount,
    this.totalCost,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] ?? 0,
      projectNo: json['projectNo'] ?? '',
      name: json['name'] ?? '',
      customerId: json['customerId'],
      customerName: json['customerName'],
      contractAmount: json['contractAmount']?.toDouble(),
      status: json['status'] ?? 1,
      signDate: json['signDate'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      descText: json['descText'],
      createdBy: json['createdBy'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      workOrderCount: json['workOrderCount'],
      totalCost: json['totalCost']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectNo': projectNo,
      'name': name,
      'customerId': customerId,
      'customerName': customerName,
      'contractAmount': contractAmount,
      'status': status,
      'signDate': signDate,
      'startDate': startDate,
      'endDate': endDate,
      'descText': descText,
      'createdBy': createdBy,
    };
  }

  String get statusText {
    switch (status) {
      case 1:
        return '进行中';
      case 2:
        return '待结算';
      case 3:
        return '已完成';
      case 4:
        return '已取消';
      default:
        return '未知';
    }
  }
}
