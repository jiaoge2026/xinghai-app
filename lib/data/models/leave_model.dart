class LeaveModel {
  final int id;
  final String leaveNo;
  final int employeeId;
  final String employeeName;
  final String leaveType; // ANNUAL/BICKER/PERSONAL/MATERNITY/OTHER
  final String startDate;
  final String endDate;
  final double totalDays;
  final String reason;
  final String status; // PENDING/APPROVED/REJECTED
  final String? approveTime;
  final String? rejectReason;

  LeaveModel({
    required this.id,
    required this.leaveNo,
    required this.employeeId,
    required this.employeeName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    required this.status,
    this.approveTime,
    this.rejectReason,
  });

  factory LeaveModel.fromJson(Map<String, dynamic> json) {
    return LeaveModel(
      id: json['id'] ?? 0,
      leaveNo: json['leaveNo'] ?? '',
      employeeId: json['employeeId'] ?? 0,
      employeeName: json['employeeName'] ?? '',
      leaveType: json['leaveType'] ?? 'PERSONAL',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      totalDays: (json['totalDays'] ?? 0).toDouble(),
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'PENDING',
      approveTime: json['approveTime'],
      rejectReason: json['rejectReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'leaveNo': leaveNo,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'leaveType': leaveType,
      'startDate': startDate,
      'endDate': endDate,
      'totalDays': totalDays,
      'reason': reason,
      'status': status,
      'approveTime': approveTime,
      'rejectReason': rejectReason,
    };
  }

  String get leaveTypeText {
    switch (leaveType) {
      case 'ANNUAL':
        return '年假';
      case 'SICK':
        return '病假';
      case 'PERSONAL':
        return '事假';
      case 'MATERNITY':
        return '产假';
      case 'PATERNITY':
        return '陪产假';
      case 'MARRIAGE':
        return '婚假';
      case 'BEREAVEMENT':
        return '丧假';
      default:
        return '其他';
    }
  }

  String get statusText {
    switch (status) {
      case 'PENDING':
        return '待审批';
      case 'APPROVED':
        return '已通过';
      case 'REJECTED':
        return '已拒绝';
      default:
        return '未知';
    }
  }
}

class LeaveBalanceModel {
  final double annualBalance;
  final double sickBalance;
  final double personalBalance;

  LeaveBalanceModel({
    required this.annualBalance,
    required this.sickBalance,
    required this.personalBalance,
  });

  factory LeaveBalanceModel.fromJson(Map<String, dynamic> json) {
    return LeaveBalanceModel(
      annualBalance: (json['annualBalance'] ?? 0).toDouble(),
      sickBalance: (json['sickBalance'] ?? 0).toDouble(),
      personalBalance: (json['personalBalance'] ?? 0).toDouble(),
    );
  }
}
