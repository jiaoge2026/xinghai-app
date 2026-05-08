class AttendanceModel {
  final int id;
  final int employeeId;
  final String employeeName;
  final String workDate;
  final String? checkInTime;
  final String? checkOutTime;
  final double? workHours;
  final String status; // NORMAL/LATE/ABSENT/EARLY_LEAVE
  final String? remark;

  AttendanceModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.workDate,
    this.checkInTime,
    this.checkOutTime,
    this.workHours,
    required this.status,
    this.remark,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] ?? 0,
      employeeId: json['employeeId'] ?? 0,
      employeeName: json['employeeName'] ?? '',
      workDate: json['workDate'] ?? '',
      checkInTime: json['checkInTime'],
      checkOutTime: json['checkOutTime'],
      workHours: json['workHours']?.toDouble(),
      status: json['status'] ?? 'NORMAL',
      remark: json['remark'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'workDate': workDate,
      'checkInTime': checkInTime,
      'checkOutTime': checkOutTime,
      'workHours': workHours,
      'status': status,
      'remark': remark,
    };
  }

  String get statusText {
    switch (status) {
      case 'NORMAL':
        return '正常';
      case 'LATE':
        return '迟到';
      case 'ABSENT':
        return '缺勤';
      case 'EARLY_LEAVE':
        return '早退';
      default:
        return '未知';
    }
  }

  bool get isCheckedIn => checkInTime != null;
  bool get isCheckedOut => checkOutTime != null;
}

class AttendanceStatModel {
  final int presentDays;
  final int lateDays;
  final int absentDays;
  final int leaveDays;
  final double totalWorkHours;

  AttendanceStatModel({
    required this.presentDays,
    required this.lateDays,
    required this.absentDays,
    required this.leaveDays,
    required this.totalWorkHours,
  });

  factory AttendanceStatModel.fromJson(Map<String, dynamic> json) {
    return AttendanceStatModel(
      presentDays: json['presentDays'] ?? 0,
      lateDays: json['lateDays'] ?? 0,
      absentDays: json['absentDays'] ?? 0,
      leaveDays: json['leaveDays'] ?? 0,
      totalWorkHours: (json['totalWorkHours'] ?? 0).toDouble(),
    );
  }
}
