import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/work_order_provider.dart';
import '../widgets/work_order_card.dart';
import 'notification_page.dart';
import 'my_page.dart';
import 'work_order_list_page.dart';
import 'attendance_page.dart';
import 'ai_session_list_page.dart';
import 'approval_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _HomeContent(),
    const WorkOrderListPage(),
    const AttendancePage(),
    const AISessionListPage(),
    const ApprovalListPage(),
    const MyPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: '工单'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: '考勤'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'AI助手'),
          BottomNavigationBarItem(icon: Icon(Icons.approval), label: '审批'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  final ScrollController _scrollController = ScrollController();

  final List<String> _tabTitles = ['今日', '待处理', '全部'];
  final List<int?> _tabStatuses = [null, AppConstants.statusAssigned, null];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final woProvider = context.read<WorkOrderProvider>();
      final authProvider = context.read<AuthProvider>();
      final engineerId = authProvider.currentUser?.id;

      if (!woProvider.isLoading && woProvider.hasMore) {
        woProvider.loadWorkOrders(engineerId: engineerId);
      }
    }
  }

  Future<void> _loadData() async {
    final woProvider = context.read<WorkOrderProvider>();
    final authProvider = context.read<AuthProvider>();
    final engineerId = authProvider.currentUser?.id;

    woProvider.loadWorkOrders(engineerId: engineerId, refresh: true);
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildQuickActions()),
              SliverToBoxAdapter(child: _buildTodayStats()),
              SliverToBoxAdapter(child: _buildWorkOrderHeader()),
              _buildWorkOrderList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  user?.realName.substring(0, 1) ?? 'U',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '您好，${user?.realName ?? '用户'}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '星海ERP移动端',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () => Get.to(() => const NotificationPage()),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '快捷入口',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionItem(
                  Icons.assignment,
                  '工单列表',
                  AppColors.statusAssigned,
                  () => Get.toNamed('/work-order/list'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionItem(
                  Icons.access_time,
                  '考勤打卡',
                  AppColors.success,
                  () => Get.toNamed('/attendance'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionItem(
                  Icons.event_busy,
                  '请假申请',
                  AppColors.warning,
                  () => Get.toNamed('/leave_list'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionItem(
                  Icons.folder,
                  '我的项目',
                  AppColors.info,
                  () => Get.toNamed('/project/list'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionItem(
                  Icons.local_shipping,
                  '配送单',
                  AppColors.primary,
                  () => Get.toNamed('/delivery_list'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionItem(
                  Icons.trending_up,
                  '商机',
                  Colors.purple,
                  () => Get.toNamed('/opportunity_list'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionItem(
                  Icons.phone_callback,
                  '来电记录',
                  AppColors.success,
                  () => Get.toNamed('/call_record_list'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionItem(
                  Icons.phone_callback,
                  '回拨请求',
                  AppColors.info,
                  () => Get.toNamed('/callback_request'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStats() {
    return Consumer<WorkOrderProvider>(
      builder: (context, woProvider, child) {
        final pendingCount = woProvider.workOrders.where((wo) => wo.status == AppConstants.statusAssigned).length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildStatItem(
                '待处理工单',
                '$pendingCount',
                Icons.pending_actions,
                AppColors.warning,
              ),
              const SizedBox(width: 24),
              _buildStatItem(
                '今日打卡',
                '已打卡',
                Icons.check_circle,
                AppColors.success,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkOrderHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '工单列表',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          TextButton(
            onPressed: () => Get.toNamed('/work-order/list'),
            child: const Text('查看全部'),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkOrderList() {
    return Consumer<WorkOrderProvider>(
      builder: (context, woProvider, child) {
        if (woProvider.isLoading && woProvider.workOrders.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (woProvider.workOrders.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text(
                    '暂无工单',
                    style: TextStyle(color: AppColors.textHint, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= woProvider.workOrders.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final wo = woProvider.workOrders[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: WorkOrderCard(
                  workOrder: wo,
                  onTap: () => Get.toNamed('/work-order/detail', arguments: wo.id),
                ),
              );
            },
            childCount: woProvider.workOrders.length > 5 ? 5 : woProvider.workOrders.length,
          ),
        );
      },
    );
  }
}
