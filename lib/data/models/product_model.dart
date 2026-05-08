class ProductModel {
  final int id;
  final String productCode;
  final String productName;
  final String? category;
  final String? brand;
  final String? model;
  final double? retailPrice;
  final double? memberPrice;
  final int? stock;
  final String? barcode;
  final String? imageUrl;
  final int? status;
  final String? spec;
  final String? unit;

  ProductModel({
    required this.id,
    required this.productCode,
    required this.productName,
    this.category,
    this.brand,
    this.model,
    this.retailPrice,
    this.memberPrice,
    this.stock,
    this.barcode,
    this.imageUrl,
    this.status,
    this.spec,
    this.unit,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? 0,
      productCode: json['productCode'] ?? '',
      productName: json['productName'] ?? '',
      category: json['category'],
      brand: json['brand'],
      model: json['model'],
      retailPrice: json['retailPrice']?.toDouble(),
      memberPrice: json['memberPrice']?.toDouble(),
      stock: json['stock'],
      barcode: json['barcode'],
      imageUrl: json['imageUrl'],
      status: json['status'],
      spec: json['spec'],
      unit: json['unit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productCode': productCode,
      'productName': productName,
      'category': category,
      'brand': brand,
      'model': model,
      'retailPrice': retailPrice,
      'memberPrice': memberPrice,
      'stock': stock,
      'barcode': barcode,
      'imageUrl': imageUrl,
      'status': status,
      'spec': spec,
      'unit': unit,
    };
  }

  ProductModel copyWith({
    int? id,
    String? productCode,
    String? productName,
    String? category,
    String? brand,
    String? model,
    double? retailPrice,
    double? memberPrice,
    int? stock,
    String? barcode,
    String? imageUrl,
    int? status,
    String? spec,
    String? unit,
  }) {
    return ProductModel(
      id: id ?? this.id,
      productCode: productCode ?? this.productCode,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      retailPrice: retailPrice ?? this.retailPrice,
      memberPrice: memberPrice ?? this.memberPrice,
      stock: stock ?? this.stock,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      spec: spec ?? this.spec,
      unit: unit ?? this.unit,
    );
  }
}
