import 'product_model.dart';

class SalesOrderModel {
  final int id;
  final String? orderNo;
  final String? storeName;
  final int? customerId;
  final String? customerName;
  final String? customerPhone;
  final double totalAmount;
  final double? actualAmount;
  final double? discountAmount;
  final String? paymentMethod;
  final int? paymentStatus;
  final String? orderDate;
  final int? deliveryStatus;
  final int? status;
  final String? remark;
  final List<SalesOrderItemModel>? items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SalesOrderModel({
    required this.id,
    this.orderNo,
    this.storeName,
    this.customerId,
    this.customerName,
    this.customerPhone,
    required this.totalAmount,
    this.actualAmount,
    this.discountAmount,
    this.paymentMethod,
    this.paymentStatus,
    this.orderDate,
    this.deliveryStatus,
    this.status,
    this.remark,
    this.items,
    this.createdAt,
    this.updatedAt,
  });

  factory SalesOrderModel.fromJson(Map<String, dynamic> json) {
    return SalesOrderModel(
      id: json['id'] ?? 0,
      orderNo: json['orderNo'],
      storeName: json['storeName'],
      customerId: json['customerId'],
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      totalAmount: json['totalAmount']?.toDouble() ?? 0.0,
      actualAmount: json['actualAmount']?.toDouble(),
      discountAmount: json['discountAmount']?.toDouble(),
      paymentMethod: json['paymentMethod'],
      paymentStatus: json['paymentStatus'],
      orderDate: json['orderDate'],
      deliveryStatus: json['deliveryStatus'],
      status: json['status'],
      remark: json['remark'],
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => SalesOrderItemModel.fromJson(e))
          .toList(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNo': orderNo,
      'storeName': storeName,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'totalAmount': totalAmount,
      'actualAmount': actualAmount,
      'discountAmount': discountAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'orderDate': orderDate,
      'deliveryStatus': deliveryStatus,
      'status': status,
      'remark': remark,
    };
  }

  String get statusText {
    switch (status) {
      case 1:
        return '待付款';
      case 2:
        return '已付款';
      case 3:
        return '已完成';
      case 4:
        return '已退款';
      case 5:
        return '已取消';
      default:
        return '未知';
    }
  }

  String get paymentStatusText {
    switch (paymentStatus) {
      case 1:
        return '未支付';
      case 2:
        return '已支付';
      case 3:
        return '已退款';
      default:
        return '未知';
    }
  }

  String get paymentMethodText {
    switch (paymentMethod) {
      case 'cash':
        return '现金';
      case 'card':
        return '刷卡';
      case 'wechat':
        return '微信';
      case 'alipay':
        return '支付宝';
      case 'transfer':
        return '转账';
      default:
        return paymentMethod ?? '未知';
    }
  }
}

class SalesOrderItemModel {
  final int id;
  final int productId;
  final String? productName;
  final String? productCode;
  final double price;
  final int quantity;
  final double? subtotal;
  final String? unit;

  SalesOrderItemModel({
    required this.id,
    required this.productId,
    this.productName,
    this.productCode,
    required this.price,
    required this.quantity,
    this.subtotal,
    this.unit,
  });

  factory SalesOrderItemModel.fromJson(Map<String, dynamic> json) {
    return SalesOrderItemModel(
      id: json['id'] ?? 0,
      productId: json['productId'] ?? 0,
      productName: json['productName'],
      productCode: json['productCode'],
      price: json['price']?.toDouble() ?? 0.0,
      quantity: json['quantity'] ?? 1,
      subtotal: json['subtotal']?.toDouble(),
      unit: json['unit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'price': price,
      'quantity': quantity,
    };
  }
}

class CartItemModel {
  final ProductModel product;
  int quantity;

  CartItemModel({
    required this.product,
    this.quantity = 1,
  });

  double get subtotal => (product.retailPrice ?? 0) * quantity;

  Map<String, dynamic> toJson() {
    return {
      'productId': product.id,
      'price': product.retailPrice,
      'quantity': quantity,
    };
  }
}
