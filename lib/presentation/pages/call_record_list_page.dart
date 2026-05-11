import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/call_record_model.dart';
import '../../data/services/call_center_service.dart';
import '../providers/auth_provider.dart';
import 'call_record_detail_page.dart';

class CallRecordListPage extends StatefulWidget {
  const CallRecordListPage({super.key});

  @override
  State<CallRecordListPage> createState() => _CallRecordListPageState();
}

class _CallRecordListPageState extends State<CallRecordListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final CallCenterService _callCenterService = CallCenterService();

  final List<String> _tabTitles = ['待处理', '已处理'];
  final List<int?> _tabStatuses = [1, 3];

  Map<int?, List<CallRecordModel>> _recordsCache = {};
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
    if (_recordsCache[status] == null) {
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
      _recordsCache[status] = [];
    }

    if (_loadingCache[status] == true || _hasMoreCache[status] != true) return;

    setState(() {
      _loadingCache[status] = true;
    });

    try {
      final page = _pageCache[status] ?? 1;
      final authProvider = context.read<AuthProvider>();
      final employeeId = authProvider.currentUser?.id;

      final list = await _callCenterService.getCallRecords(
        status: status,
        employeeId: employeeId,
        page: page,
      );

      setState(() {
        if (refresh) {
          _recordsCache[status] = list;
        } else {
          _recordsCache[status] = [
            ...(_recordsCache[status] ?? []),
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
        return AppColors.success;
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
          '来电记录',
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
          return _buildCallRecordList(status);
        }),
      ),
    );
  }

  Widget _buildCallRecordList(int? status) {
    final records = _recordsCache[status] ?? [];
    final isLoading = _loadingCache[status] ?? false;
    final hasMore = _hasMoreCache[status] ?? true;

    if (isLoading && records.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (records.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: records.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= records.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final record = records[index];
          return _buildCallRecordCard(record);
        },
      ),
    );
  }

  Widget _buildCallRecordCard(CallRecordModel record) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => Get.toNamed('/call_record_detail', arguments: record.id),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (record.callType == 1 ? AppColors.success : AppColors.info).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  record.callType == 1 ? Icons.call_received : Icons.call_made,
                  color: record.callType == 1 ? AppColors.success : AppColors.info,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          record.callerNumber,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(record.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            record.statusText,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(record.status),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (record.customerName != null)
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(
                            record.customerName!,
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          record.callTime ?? '',
                          style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.timer_outlined, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          record.formattedDuration,
                          style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textHint),
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
            Icons.call_missed_outgoing,
            size: 80,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无来电记录',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '当前筛选条件下没有来电记录',
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
