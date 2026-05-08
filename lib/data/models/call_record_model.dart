class CallRecordModel {
  final int id;
  final String callId;
  final String callerNumber;
  final int callType;
  final String? callTime;
  final int talkDuration;
  final int? customerId;
  final String? customerName;
  final int status;
  final String? associatedType;
  final int? associatedId;
  final String? processRemark;
  final DateTime? createdAt;

  CallRecordModel({
    required this.id,
    required this.callId,
    required this.callerNumber,
    required this.callType,
    this.callTime,
    required this.talkDuration,
    this.customerId,
    this.customerName,
    required this.status,
    this.associatedType,
    this.associatedId,
    this.processRemark,
    this.createdAt,
  });

  factory CallRecordModel.fromJson(Map<String, dynamic> json) {
    return CallRecordModel(
      id: json['id'] ?? 0,
      callId: json['callId'] ?? '',
      callerNumber: json['callerNumber'] ?? '',
      callType: json['callType'] ?? 1,
      callTime: json['callTime'],
      talkDuration: json['talkDuration'] ?? 0,
      customerId: json['customerId'],
      customerName: json['customerName'],
      status: json['status'] ?? 1,
      associatedType: json['associatedType'],
      associatedId: json['associatedId'],
      processRemark: json['processRemark'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'callId': callId,
      'callerNumber': callerNumber,
      'callType': callType,
      'callTime': callTime,
      'talkDuration': talkDuration,
      'customerId': customerId,
      'customerName': customerName,
      'status': status,
      'associatedType': associatedType,
      'associatedId': associatedId,
      'processRemark': processRemark,
    };
  }

  CallRecordModel copyWith({
    int? id,
    String? callId,
    String? callerNumber,
    int? callType,
    String? callTime,
    int? talkDuration,
    int? customerId,
    String? customerName,
    int? status,
    String? associatedType,
    int? associatedId,
    String? processRemark,
    DateTime? createdAt,
  }) {
    return CallRecordModel(
      id: id ?? this.id,
      callId: callId ?? this.callId,
      callerNumber: callerNumber ?? this.callerNumber,
      callType: callType ?? this.callType,
      callTime: callTime ?? this.callTime,
      talkDuration: talkDuration ?? this.talkDuration,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      status: status ?? this.status,
      associatedType: associatedType ?? this.associatedType,
      associatedId: associatedId ?? this.associatedId,
      processRemark: processRemark ?? this.processRemark,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get callTypeText {
    switch (callType) {
      case 1:
        return '呼入';
      case 2:
        return '呼出';
      default:
        return '未知';
    }
  }

  String get statusText {
    switch (status) {
      case 1:
        return '待处理';
      case 2:
        return '处理中';
      case 3:
        return '已处理';
      default:
        return '未知';
    }
  }

  String get formattedDuration {
    final minutes = talkDuration ~/ 60;
    final seconds = talkDuration % 60;
    return '${minutes}分${seconds}秒';
  }
}

class CallbackRequestModel {
  final int id;
  final String customerPhone;
  final String? customerName;
  final int requestType;
  final int priority;
  final int status;
  final String? assignedEmployeeName;
  final String? createTime;

  CallbackRequestModel({
    required this.id,
    required this.customerPhone,
    this.customerName,
    required this.requestType,
    required this.priority,
    required this.status,
    this.assignedEmployeeName,
    this.createTime,
  });

  factory CallbackRequestModel.fromJson(Map<String, dynamic> json) {
    return CallbackRequestModel(
      id: json['id'] ?? 0,
      customerPhone: json['customerPhone'] ?? '',
      customerName: json['customerName'],
      requestType: json['requestType'] ?? 1,
      priority: json['priority'] ?? 2,
      status: json['status'] ?? 1,
      assignedEmployeeName: json['assignedEmployeeName'],
      createTime: json['createTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerPhone': customerPhone,
      'customerName': customerName,
      'requestType': requestType,
      'priority': priority,
      'status': status,
      'assignedEmployeeName': assignedEmployeeName,
      'createTime': createTime,
    };
  }

  String get requestTypeText {
    switch (requestType) {
      case 1:
        return '咨询';
      case 2:
        return '投诉';
      case 3:
        return '售后';
      default:
        return '其他';
    }
  }

  String get priorityText {
    switch (priority) {
      case 1:
        return '高';
      case 2:
        return '中';
      case 3:
        return '低';
      default:
        return '中';
    }
  }

  String get statusText {
    switch (status) {
      case 1:
        return '待处理';
      case 2:
        return '处理中';
      case 3:
        return '已完成';
      default:
        return '未知';
    }
  }

  bool get isHighPriority => priority == 1;
}
