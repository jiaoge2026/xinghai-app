class EngineerModel {
  final int id;
  final String name;
  final String? phone;
  final String? avatar;
  final int status;
  final String? skillTags;
  final String? area;
  final double? avgRating;
  final int? todayWoCount;
  final int? totalWoCount;

  EngineerModel({
    required this.id,
    required this.name,
    this.phone,
    this.avatar,
    required this.status,
    this.skillTags,
    this.area,
    this.avgRating,
    this.todayWoCount,
    this.totalWoCount,
  });

  factory EngineerModel.fromJson(Map<String, dynamic> json) {
    return EngineerModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'],
      avatar: json['avatar'],
      status: json['status'] ?? 1,
      skillTags: json['skillTags'],
      area: json['area'],
      avgRating: json['avgRating']?.toDouble(),
      todayWoCount: json['todayWoCount'],
      totalWoCount: json['totalWoCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'avatar': avatar,
      'status': status,
      'skillTags': skillTags,
      'area': area,
      'avgRating': avgRating,
      'todayWoCount': todayWoCount,
      'totalWoCount': totalWoCount,
    };
  }

  bool get isAccepting => status == 1;
  bool get isPaused => status == 2;
}
