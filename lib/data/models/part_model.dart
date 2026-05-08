class PartModel {
  final int id;
  final String? partNo;
  final String name;
  final String? spec;
  final String? unit;
  final double? unitPrice;
  final int? stockQuantity;
  final int? warehouseId;

  PartModel({
    required this.id,
    this.partNo,
    required this.name,
    this.spec,
    this.unit,
    this.unitPrice,
    this.stockQuantity,
    this.warehouseId,
  });

  factory PartModel.fromJson(Map<String, dynamic> json) {
    return PartModel(
      id: json['id'] ?? 0,
      partNo: json['partNo'],
      name: json['name'] ?? '',
      spec: json['spec'],
      unit: json['unit'],
      unitPrice: json['unitPrice']?.toDouble(),
      stockQuantity: json['stockQuantity'],
      warehouseId: json['warehouseId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partNo': partNo,
      'name': name,
      'spec': spec,
      'unit': unit,
      'unitPrice': unitPrice,
      'stockQuantity': stockQuantity,
      'warehouseId': warehouseId,
    };
  }
}
