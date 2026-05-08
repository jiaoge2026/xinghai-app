import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/services/dashboard_service.dart';
import 'fsm_dashboard_page.dart';
import 'finance_dashboard_page.dart';
import 'inventory_dashboard_page.dart';
import '../pages/product_list_page.dart';
import '../pages/sales_order_list_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DashboardService _dashboardService = DashboardService();
  
  DashboardOverviewModel? _overview;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final overview = await _dashboardService.getOverview();
      setState(() {
        _overview = overview;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败：$e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('经营驾驶舱', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSalesOverview(),
                    const SizedBox(height: 16),
                    _buildCoreMetrics(),
                    const SizedBox(height: 16),
                    _buildModuleEntry(),
                    const SizedBox(height: 16),
                    _buildTrendChart(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSalesOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('今日销售额', style: TextStyle(color: Colors.white70, fontSize: 14)),
              _buildGrowthBadge(_overview?.monthSalesGrowth),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '¥${_overview?.todaySales.toStringAsFixed(2) ?? '0.00'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('本月销售额', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      '¥${_overview?.monthSales.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white30,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('本月订单', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      '${_overview?.monthOrders ?? 0} 单',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthBadge(double? growth) {
    if (growth == null) return const SizedBox.shrink();
    final isPositive = growth >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            '${isPositive ? '+' : ''}${growth.toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildCoreMetrics() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            '今日订单',
            '${_overview?.todayOrders ?? 0}',
            Icons.receipt,
            AppColors.info,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            '待派工单',
            '${_overview?.pendingWorkOrders ?? 0}',
            Icons.pending_actions,
            AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(title, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleEntry() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('模块入口', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildModuleButton('FSM工单', Icons.build, AppColors.info, () {
                Get.to(() => const FsmDashboardPage());
              }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModuleButton('财务报表', Icons.account_balance, AppColors.success, () {
                Get.to(() => const FinanceDashboardPage());
              }),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildModuleButton('库存管理', Icons.inventory, AppColors.warning, () {
                Get.to(() => const InventoryDashboardPage());
              }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModuleButton('零售门店', Icons.store, AppColors.error, () {
                Get.to(() => const ProductListPage());
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModuleButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('本月销售趋势', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: _overview?.salesTrend != null && _overview!.salesTrend!.isNotEmpty
                ? _buildSimpleChart()
                : Center(
                    child: Text('暂无数据', style: TextStyle(color: AppColors.textHint)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleChart() {
    final trend = _overview?.salesTrend ?? [];
    if (trend.isEmpty) return const SizedBox.shrink();

    final maxAmount = trend.map((e) => e.amount).reduce((a, b) => a > b ? a : b);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: trend.take(7).map((item) {
        final heightRatio = maxAmount > 0 ? item.amount / maxAmount : 0.0;
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 30,
              height: (100 * heightRatio).clamp(4.0, 100.0),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.date.substring(5, 7),
              style: TextStyle(fontSize: 10, color: AppColors.textHint),
            ),
          ],
        );
      }).toList(),
    );
  }
}
