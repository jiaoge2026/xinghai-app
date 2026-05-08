class DashboardOverviewModel {
  final double todaySales;
  final double monthSales;
  final double? monthSalesGrowth;
  final int todayOrders;
  final int monthOrders;
  final double? monthOrderGrowth;
  final int pendingWorkOrders;
  final int inProgressWorkOrders;
  final int completedWorkOrders;
  final int inventoryAlerts;
  final int pendingCalls;
  final List<SalesTrendModel>? salesTrend;
  final List<OrderTrendModel>? orderTrend;

  DashboardOverviewModel({
    this.todaySales = 0,
    this.monthSales = 0,
    this.monthSalesGrowth,
    this.todayOrders = 0,
    this.monthOrders = 0,
    this.monthOrderGrowth,
    this.pendingWorkOrders = 0,
    this.inProgressWorkOrders = 0,
    this.completedWorkOrders = 0,
    this.inventoryAlerts = 0,
    this.pendingCalls = 0,
    this.salesTrend,
    this.orderTrend,
  });

  factory DashboardOverviewModel.fromJson(Map<String, dynamic> json) {
    return DashboardOverviewModel(
      todaySales: json['todaySales']?.toDouble() ?? 0,
      monthSales: json['monthSales']?.toDouble() ?? 0,
      monthSalesGrowth: json['monthSalesGrowth']?.toDouble(),
      todayOrders: json['todayOrders'] ?? 0,
      monthOrders: json['monthOrders'] ?? 0,
      monthOrderGrowth: json['monthOrderGrowth']?.toDouble(),
      pendingWorkOrders: json['pendingWorkOrders'] ?? 0,
      inProgressWorkOrders: json['inProgressWorkOrders'] ?? 0,
      completedWorkOrders: json['completedWorkOrders'] ?? 0,
      inventoryAlerts: json['inventoryAlerts'] ?? 0,
      pendingCalls: json['pendingCalls'] ?? 0,
      salesTrend: (json['salesTrend'] as List<dynamic>?)
          ?.map((e) => SalesTrendModel.fromJson(e))
          .toList(),
      orderTrend: (json['orderTrend'] as List<dynamic>?)
          ?.map((e) => OrderTrendModel.fromJson(e))
          .toList(),
    );
  }
}

class SalesTrendModel {
  final String date;
  final double amount;

  SalesTrendModel({required this.date, required this.amount});

  factory SalesTrendModel.fromJson(Map<String, dynamic> json) {
    return SalesTrendModel(
      date: json['date'] ?? '',
      amount: json['amount']?.toDouble() ?? 0,
    );
  }
}

class OrderTrendModel {
  final String date;
  final int count;

  OrderTrendModel({required this.date, required this.count});

  factory OrderTrendModel.fromJson(Map<String, dynamic> json) {
    return OrderTrendModel(
      date: json['date'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class FsmDashboardModel {
  final int pendingCount;
  final int assignedCount;
  final int inProgressCount;
  final int completedCount;
  final int cancelledCount;
  final List<EngineerWorkOrderStatModel>? engineerRanking;
  final List<WorkOrderTypeStatModel>? typeStats;

  FsmDashboardModel({
    this.pendingCount = 0,
    this.assignedCount = 0,
    this.inProgressCount = 0,
    this.completedCount = 0,
    this.cancelledCount = 0,
    this.engineerRanking,
    this.typeStats,
  });

  factory FsmDashboardModel.fromJson(Map<String, dynamic> json) {
    return FsmDashboardModel(
      pendingCount: json['pendingCount'] ?? 0,
      assignedCount: json['assignedCount'] ?? 0,
      inProgressCount: json['inProgressCount'] ?? 0,
      completedCount: json['completedCount'] ?? 0,
      cancelledCount: json['cancelledCount'] ?? 0,
      engineerRanking: (json['engineerRanking'] as List<dynamic>?)
          ?.map((e) => EngineerWorkOrderStatModel.fromJson(e))
          .toList(),
      typeStats: (json['typeStats'] as List<dynamic>?)
          ?.map((e) => WorkOrderTypeStatModel.fromJson(e))
          .toList(),
    );
  }
}

class EngineerWorkOrderStatModel {
  final int engineerId;
  final String? engineerName;
  final int completedCount;
  final double? goodRate;
  final double? avgResponseTime;

  EngineerWorkOrderStatModel({
    required this.engineerId,
    this.engineerName,
    this.completedCount = 0,
    this.goodRate,
    this.avgResponseTime,
  });

  factory EngineerWorkOrderStatModel.fromJson(Map<String, dynamic> json) {
    return EngineerWorkOrderStatModel(
      engineerId: json['engineerId'] ?? 0,
      engineerName: json['engineerName'],
      completedCount: json['completedCount'] ?? 0,
      goodRate: json['goodRate']?.toDouble(),
      avgResponseTime: json['avgResponseTime']?.toDouble(),
    );
  }
}

class WorkOrderTypeStatModel {
  final String? typeName;
  final int count;

  WorkOrderTypeStatModel({this.typeName, this.count = 0});

  factory WorkOrderTypeStatModel.fromJson(Map<String, dynamic> json) {
    return WorkOrderTypeStatModel(
      typeName: json['typeName'],
      count: json['count'] ?? 0,
    );
  }
}

class FinanceDashboardModel {
  final double monthIncome;
  final double monthExpense;
  final double accountsReceivable;
  final List<FinanceTrendModel>? trend;

  FinanceDashboardModel({
    this.monthIncome = 0,
    this.monthExpense = 0,
    this.accountsReceivable = 0,
    this.trend,
  });

  factory FinanceDashboardModel.fromJson(Map<String, dynamic> json) {
    return FinanceDashboardModel(
      monthIncome: json['monthIncome']?.toDouble() ?? 0,
      monthExpense: json['monthExpense']?.toDouble() ?? 0,
      accountsReceivable: json['accountsReceivable']?.toDouble() ?? 0,
      trend: (json['trend'] as List<dynamic>?)
          ?.map((e) => FinanceTrendModel.fromJson(e))
          .toList(),
    );
  }
}

class FinanceTrendModel {
  final String month;
  final double income;
  final double expense;

  FinanceTrendModel({
    required this.month,
    required this.income,
    required this.expense,
  });

  factory FinanceTrendModel.fromJson(Map<String, dynamic> json) {
    return FinanceTrendModel(
      month: json['month'] ?? '',
      income: json['income']?.toDouble() ?? 0,
      expense: json['expense']?.toDouble() ?? 0,
    );
  }
}

class InventoryDashboardModel {
  final int totalQuantity;
  final double totalValue;
  final int alertCount;
  final List<InventoryAlertModel>? alerts;
  final List<InventoryTrendModel>? trend;

  InventoryDashboardModel({
    this.totalQuantity = 0,
    this.totalValue = 0,
    this.alertCount = 0,
    this.alerts,
    this.trend,
  });

  factory InventoryDashboardModel.fromJson(Map<String, dynamic> json) {
    return InventoryDashboardModel(
      totalQuantity: json['totalQuantity'] ?? 0,
      totalValue: json['totalValue']?.toDouble() ?? 0,
      alertCount: json['alertCount'] ?? 0,
      alerts: (json['alerts'] as List<dynamic>?)
          ?.map((e) => InventoryAlertModel.fromJson(e))
          .toList(),
      trend: (json['trend'] as List<dynamic>?)
          ?.map((e) => InventoryTrendModel.fromJson(e))
          .toList(),
    );
  }
}

class InventoryAlertModel {
  final int productId;
  final String? productName;
  final int currentStock;
  final int minStock;

  InventoryAlertModel({
    required this.productId,
    this.productName,
    this.currentStock = 0,
    this.minStock = 0,
  });

  factory InventoryAlertModel.fromJson(Map<String, dynamic> json) {
    return InventoryAlertModel(
      productId: json['productId'] ?? 0,
      productName: json['productName'],
      currentStock: json['currentStock'] ?? 0,
      minStock: json['minStock'] ?? 0,
    );
  }
}

class InventoryTrendModel {
  final String date;
  final int inQuantity;
  final int outQuantity;

  InventoryTrendModel({
    required this.date,
    required this.inQuantity,
    required this.outQuantity,
  });

  factory InventoryTrendModel.fromJson(Map<String, dynamic> json) {
    return InventoryTrendModel(
      date: json['date'] ?? '',
      inQuantity: json['inQuantity'] ?? 0,
      outQuantity: json['outQuantity'] ?? 0,
    );
  }
}

class EngineerRankingModel {
  final int engineerId;
  final String? engineerName;
  final String? avatar;
  final int completedCount;
  final double? goodRate;
  final double? avgScore;
  final int rank;

  EngineerRankingModel({
    required this.engineerId,
    this.engineerName,
    this.avatar,
    this.completedCount = 0,
    this.goodRate,
    this.avgScore,
    this.rank = 0,
  });

  factory EngineerRankingModel.fromJson(Map<String, dynamic> json) {
    return EngineerRankingModel(
      engineerId: json['engineerId'] ?? 0,
      engineerName: json['engineerName'],
      avatar: json['avatar'],
      completedCount: json['completedCount'] ?? 0,
      goodRate: json['goodRate']?.toDouble(),
      avgScore: json['avgScore']?.toDouble(),
      rank: json['rank'] ?? 0,
    );
  }
}
