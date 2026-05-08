import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/sales_order_model.dart';
import '../../data/services/retail_service.dart';

class SalesOrderListPage extends StatefulWidget {
  const SalesOrderListPage({super.key});

  @override
  State<SalesOrderListPage> createState() => _SalesOrderListPageState();
}

class _SalesOrderListPageState extends State<SalesOrderListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RetailService _retailService = RetailService();
  final ScrollController _scrollController = ScrollController();

  final List<String> _tabTitles = ['全部', '待付款', '已付款', '已退款'];
  final List<int?> _tabStatuses = [null, 1, 2, 4];

  Map<int?, List<SalesOrderModel>> _ordersCache = {};
  Map<int?, bool> _loadingCache = {};
  Map<int?, bool> _hasMoreCache = {};
  Map<int?, int> _pageCache = {};
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabTitles.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);

    for (int i = 0; i < _tabTitles.length; i++) {
      _loadingCache[_tabStatuses[i]] = false;
      _hasMoreCache[_tabStatuses[i]] = true;
      _pageCache[_tabStatuses[i]] = 1;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders(refresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _currentTabIndex = _tabController.index;
    });

    final status = _tabStatuses[_currentTabIndex];
    if (_ordersCache[status] == null) {
      _loadOrders(refresh: true);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final status = _tabStatuses[_currentTabIndex];
      if (_loadingCache[status] != true && _hasMoreCache[status] == true) {
        _loadOrders();
      }
    }
  }

  Future<void> _loadOrders({bool refresh = false}) async {
    final status = _tabStatuses[_currentTabIndex];

    if (refresh) {
      _pageCache[status] = 1;
      _hasMoreCache[status] = true;
      _ordersCache[status] = [];
    }

    if (_loadingCache[status] == true || _hasMoreCache[status] != true) return;

    setState(() {
      _loadingCache[status] = true;
    });

    try {
      final page = _pageCache[status] ?? 1;
      final list = await _retailService.getOrders(status: status, page: page);

      setState(() {
        if (refresh) {
          _ordersCache[status] = list;
        } else {
          _ordersCache[status] = [
            ...(_ordersCache[status] ?? []),
            ...list,
          ];
        }

        if (list.length < 20) {
          _hasMoreCache[status] = false;
        }
        _pageCache[status] = page + 1;
        _loadingCache[status] = false;
      });
    } catch (e) {
      setState(() {
        _loadingCache[status] = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载失败：$e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadOrders(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '销售订单',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: false,
          tabs: _tabTitles.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(_tabTitles.length, (index) {
          final status = _tabStatuses[index];
          return _buildOrderList(status);
        }),
      ),
    );
  }

  Widget _buildOrderList(int? status) {
    final orders = _ordersCache[status] ?? [];
    final isLoading = _loadingCache[status] ?? false;
    final hasMore = _hasMoreCache[status] ?? true;

    if (isLoading && orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (orders.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: orders.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= orders.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final order = orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(SalesOrderModel order) {
    Color statusColor;
    switch (order.status) {
      case 1:
        statusColor = AppColors.warning;
        break;
      case 2:
        statusColor = AppColors.success;
        break;
      case 3:
        statusColor = AppColors.info;
        break;
      case 4:
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.textHint;
    }

    return GestureDetector(
      onTap: () => _showOrderDetail(order),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.orderNo ?? '订单#${order.id}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    order.statusText,
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.store, size: 16, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(order.storeName ?? '-', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(order.customerName ?? '散客', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                if (order.customerPhone != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.phone_outlined, size: 16, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(order.customerPhone!, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.orderDate ?? '',
                  style: TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
                Text(
                  '¥${order.actualAmount?.toStringAsFixed(2) ?? order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetail(SalesOrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('订单详情', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildDetailRow('订单号', order.orderNo ?? '-'),
              _buildDetailRow('门店', order.storeName ?? '-'),
              _buildDetailRow('客户', order.customerName ?? '散客'),
              _buildDetailRow('电话', order.customerPhone ?? '-'),
              _buildDetailRow('下单时间', order.orderDate ?? '-'),
              _buildDetailRow('支付方式', order.paymentMethodText),
              _buildDetailRow('支付状态', order.paymentStatusText),
              const Divider(),
              if (order.items != null && order.items!.isNotEmpty) ...[
                const Text('商品明细', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...order.items!.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item.productName ?? '商品'} x ${item.quantity}'),
                      Text('¥${(item.price * item.quantity).toStringAsFixed(2)}'),
                    ],
                  ),
                )),
                const Divider(),
              ],
              _buildDetailRow('商品总额', '¥${order.totalAmount.toStringAsFixed(2)}'),
              if (order.discountAmount != null && order.discountAmount! > 0)
                _buildDetailRow('折扣', '-¥${order.discountAmount!.toStringAsFixed(2)}'),
              _buildDetailRow('实付金额', '¥${order.actualAmount?.toStringAsFixed(2) ?? '-'}', isHighlight: true),
              const SizedBox(height: 16),
              if (order.status == 1)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          try {
                            await _retailService.payOrder(order.id, 'cash');
                            Get.snackbar('成功', '收款成功', backgroundColor: AppColors.success);
                            _loadOrders(refresh: true);
                          } catch (e) {
                            Get.snackbar('错误', '收款失败: $e', backgroundColor: AppColors.error);
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('收款'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          try {
                            await _retailService.refundOrder(order.id);
                            Get.snackbar('成功', '退款成功', backgroundColor: AppColors.success);
                            _loadOrders(refresh: true);
                          } catch (e) {
                            Get.snackbar('错误', '退款失败: $e', backgroundColor: AppColors.error);
                          }
                        },
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                        child: const Text('退款'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? AppColors.error : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无订单',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
