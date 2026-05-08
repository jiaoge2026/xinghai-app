import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/delivery_order_model.dart';
import '../../data/services/delivery_service.dart';
import '../providers/auth_provider.dart';
import 'delivery_detail_page.dart';

class DeliveryListPage extends StatefulWidget {
  const DeliveryListPage({super.key});

  @override
  State<DeliveryListPage> createState() => _DeliveryListPageState();
}

class _DeliveryListPageState extends State<DeliveryListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final DeliveryService _deliveryService = DeliveryService();

  final List<String> _tabTitles = ['待取货', '配送中', '已完成'];
  final List<int?> _tabStatuses = [1, 3, 5];

  Map<int?, List<DeliveryOrderModel>> _ordersCache = {};
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
      _loadData(refresh: true);
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
      _loadData(refresh: true);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final status = _tabStatuses[_currentTabIndex];
      if (_loadingCache[status] != true && _hasMoreCache[status] == true) {
        _loadData();
      }
    }
  }

  Future<void> _loadData({bool refresh = false}) async {
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
      final authProvider = context.read<AuthProvider>();
      final driverId = authProvider.currentUser?.id;

      final list = await _deliveryService.getDeliveryOrders(
        driverId: driverId,
        status: status,
        page: page,
      );

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
    await _loadData(refresh: true);
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return AppColors.warning;
      case 2:
        return AppColors.info;
      case 3:
        return AppColors.primary;
      case 4:
        return AppColors.success;
      case 5:
        return AppColors.textHint;
      default:
        return AppColors.textSecondary;
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
        title: const Text(
          '配送单',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: false,
          tabs: _tabTitles.map((title) => Tab(text: title)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(_tabTitles.length, (index) {
          final status = _tabStatuses[index];
          return _buildDeliveryList(status);
        }),
      ),
    );
  }

  Widget _buildDeliveryList(int? status) {
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
          return _buildDeliveryCard(order);
        },
      ),
    );
  }

  Widget _buildDeliveryCard(DeliveryOrderModel order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => Get.toNamed('/delivery_detail', arguments: order.id),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.deliveryNo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order.statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(order.status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    order.customerName,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.customerAddress,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '数量: ${order.totalQuantity.toStringAsFixed(1)} | 重量: ${order.totalWeight.toStringAsFixed(1)}kg',
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                  ),
                  if (order.pickupTime != null)
                    Text(
                      '取货时间: ${order.pickupTime}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 80,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无配送单',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '当前筛选条件下没有配送单',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
