class OpportunityModel {
  final int id;
  final String opportunityNo;
  final String opportunityName;
  final String customerName;
  final double estimatedAmount;
  final int probability;
  final String? expectedCloseDate;
  final int stage;
  final String? source;
  final String employeeName;
  final int status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OpportunityModel({
    required this.id,
    required this.opportunityNo,
    required this.opportunityName,
    required this.customerName,
    required this.estimatedAmount,
    required this.probability,
    this.expectedCloseDate,
    required this.stage,
    this.source,
    required this.employeeName,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory OpportunityModel.fromJson(Map<String, dynamic> json) {
    return OpportunityModel(
      id: json['id'] ?? 0,
      opportunityNo: json['opportunityNo'] ?? '',
      opportunityName: json['opportunityName'] ?? '',
      customerName: json['customerName'] ?? '',
      estimatedAmount: (json['estimatedAmount'] ?? 0).toDouble(),
      probability: json['probability'] ?? 0,
      expectedCloseDate: json['expectedCloseDate'],
      stage: json['stage'] ?? 1,
      source: json['source'],
      employeeName: json['employeeName'] ?? '',
      status: json['status'] ?? 1,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'opportunityNo': opportunityNo,
      'opportunityName': opportunityName,
      'customerName': customerName,
      'estimatedAmount': estimatedAmount,
      'probability': probability,
      'expectedCloseDate': expectedCloseDate,
      'stage': stage,
      'source': source,
      'employeeName': employeeName,
      'status': status,
    };
  }

  OpportunityModel copyWith({
    int? id,
    String? opportunityNo,
    String? opportunityName,
    String? customerName,
    double? estimatedAmount,
    int? probability,
    String? expectedCloseDate,
    int? stage,
    String? source,
    String? employeeName,
    int? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OpportunityModel(
      id: id ?? this.id,
      opportunityNo: opportunityNo ?? this.opportunityNo,
      opportunityName: opportunityName ?? this.opportunityName,
      customerName: customerName ?? this.customerName,
      estimatedAmount: estimatedAmount ?? this.estimatedAmount,
      probability: probability ?? this.probability,
      expectedCloseDate: expectedCloseDate ?? this.expectedCloseDate,
      stage: stage ?? this.stage,
      source: source ?? this.source,
      employeeName: employeeName ?? this.employeeName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get stageText {
    switch (stage) {
      case 1:
        return '新商机';
      case 2:
        return '已Qualified';
      case 3:
        return '提案';
      case 4:
        return '谈判';
      case 5:
        return '成交';
      case 6:
        return '输单';
      default:
        return '未知';
    }
  }

  String get statusText {
    return status == 1 ? '进行中' : '已关闭';
  }

  static String getStageName(int stage) {
    switch (stage) {
      case 1:
        return '新商机';
      case 2:
        return '已Qualified';
      case 3:
        return '提案';
      case 4:
        return '谈判';
      case 5:
        return '成交';
      case 6:
        return '输单';
      default:
        return '未知';
    }
  }
}

class CustomerFollowUpModel {
  final int id;
  final String customerName;
  final String? contactName;
  final int followUpType;
  final String? followUpDate;
  final String content;
  final String? nextPlanDate;
  final String? followUpResult;
  final String employeeName;
  final DateTime? createdAt;

  CustomerFollowUpModel({
    required this.id,
    required this.customerName,
    this.contactName,
    required this.followUpType,
    this.followUpDate,
    required this.content,
    this.nextPlanDate,
    this.followUpResult,
    required this.employeeName,
    this.createdAt,
  });

  factory CustomerFollowUpModel.fromJson(Map<String, dynamic> json) {
    return CustomerFollowUpModel(
      id: json['id'] ?? 0,
      customerName: json['customerName'] ?? '',
      contactName: json['contactName'],
      followUpType: json['followUpType'] ?? 1,
      followUpDate: json['followUpDate'],
      content: json['content'] ?? '',
      nextPlanDate: json['nextPlanDate'],
      followUpResult: json['followUpResult'],
      employeeName: json['employeeName'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerName': customerName,
      'contactName': contactName,
      'followUpType': followUpType,
      'followUpDate': followUpDate,
      'content': content,
      'nextPlanDate': nextPlanDate,
      'followUpResult': followUpResult,
      'employeeName': employeeName,
    };
  }

  String get followUpTypeText {
    switch (followUpType) {
      case 1:
        return '电话';
      case 2:
        return '拜访';
      case 3:
        return '微信';
      case 4:
        return '邮件';
      default:
        return '其他';
    }
  }

  static String getFollowUpTypeName(int type) {
    switch (type) {
      case 1:
        return '电话';
      case 2:
        return '拜访';
      case 3:
        return '微信';
      case 4:
        return '邮件';
      default:
        return '其他';
    }
  }
}
