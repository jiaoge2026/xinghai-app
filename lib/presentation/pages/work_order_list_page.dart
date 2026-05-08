import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/work_order_model.dart';
import '../../data/services/work_order_service.dart';
import '../providers/auth_provider.dart';
import '../providers/work_order_provider.dart';
import '../widgets/work_order_card.dart';
import 'work_order_detail_page.dart';

class WorkOrderListPage extends StatefulWidget {
  const WorkOrderListPage({super.key});

  @override
  State<WorkOrderListPage> createState() => _WorkOrderListPageState();
}

class _WorkOrderListPageState extends State<WorkOrderListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final WorkOrderService _workOrderService = WorkOrderService();

  final List<String> _tabTitles = ['全部', '待派单', '进行中', '待结算', '已完成'];
  final List<int?> _tabStatuses = [null, 1, 3, 3, 4];

  Map<int?, List<WorkOrderModel>> _workOrdersCache = {};
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
    if (_workOrdersCache[status] == null) {
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
      _workOrdersCache[status] = [];
    }

    if (_loadingCache[status] == true || _hasMoreCache[status] != true) return;

    setState(() {
      _loadingCache[status] = true;
    });

    try {
      final page = _pageCache[status] ?? 1;
      final authProvider = context.read<AuthProvider>();
      final engineerId = authProvider.currentUser?.id;

      final list = await _workOrderService.getPage(
        page: page,
        status: status,
        engineerId: engineerId,
      );

      setState(() {
        if (refresh) {
          _workOrdersCache[status] = list;
        } else {
          _workOrdersCache[status] = [
            ...(_workOrdersCache[status] ?? []),
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

  bool _isProjectManager() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    return user?.isServiceManager == true || user?.isAdmin == true;
  }

  void _showCreateWorkOrderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建工单'),
        content: const Text('新建工单功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
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
          '我的工单',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: false,
          tabs: _tabTitles.asMap().entries.map((entry) {
            final index = entry.key;
            final title = entry.value;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title),
                  if (_getUnreadCount(_tabStatuses[index]) > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_getUnreadCount(_tabStatuses[index])}',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.getStatusColor(_tabStatuses[index] ?? 0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(_tabTitles.length, (index) {
          final status = _tabStatuses[index];
          return _buildWorkOrderList(status);
        }),
      ),
      floatingActionButton: _isProjectManager()
          ? FloatingActionButton(
              onPressed: _showCreateWorkOrderDialog,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  int _getUnreadCount(int? status) {
    if (status == null) {
      int total = 0;
      for (var woList in _workOrdersCache.values) {
        total += woList.length;
      }
      return total;
    }
    return _workOrdersCache[status]?.length ?? 0;
  }

  Widget _buildWorkOrderList(int? status) {
    final workOrders = _workOrdersCache[status] ?? [];
    final isLoading = _loadingCache[status] ?? false;
    final hasMore = _hasMoreCache[status] ?? true;

    if (isLoading && workOrders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (workOrders.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: workOrders.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= workOrders.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final wo = workOrders[index];
          return WorkOrderCard(
            workOrder: wo,
            onTap: () => Get.to(
              () => const WorkOrderDetailPage(),
              arguments: wo.id,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无工单',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '当前筛选条件下没有工单记录',
            style: TextStyle(
              color: AppColors.textHint.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
