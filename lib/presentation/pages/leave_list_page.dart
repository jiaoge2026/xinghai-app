import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/leave_model.dart';
import '../../data/services/leave_service.dart';
import '../providers/auth_provider.dart';
import 'leave_apply_page.dart';

class LeaveListPage extends StatefulWidget {
  const LeaveListPage({super.key});

  @override
  State<LeaveListPage> createState() => _LeaveListPageState();
}

class _LeaveListPageState extends State<LeaveListPage> {
  final LeaveService _service = LeaveService();
  final ScrollController _scrollController = ScrollController();

  List<LeaveModel> _leaveList = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _page = 1;
  String _currentFilter = ''; // '', 'PENDING', 'APPROVED', 'REJECTED'

  final List<Map<String, String>> _filters = [
    {'value': '', 'label': '全部'},
    {'value': 'PENDING', 'label': '待审批'},
    {'value': 'APPROVED', 'label': '已通过'},
    {'value': 'REJECTED', 'label': '已拒绝'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; });

    try {
      final authProvider = context.read<AuthProvider>();
      final employeeId = authProvider.currentUser?.id;

      final list = await _service.getPage(
        employeeId: employeeId,
        status: _currentFilter.isEmpty ? null : _currentFilter,
        page: 1,
        pageSize: 20,
      );

      setState(() {
        _leaveList = list;
        _page = 1;
        _hasMore = list.length >= 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败：$e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() { _isLoading = true; });

    try {
      final authProvider = context.read<AuthProvider>();
      final employeeId = authProvider.currentUser?.id;

      final list = await _service.getPage(
        employeeId: employeeId,
        status: _currentFilter.isEmpty ? null : _currentFilter,
        page: _page + 1,
        pageSize: 20,
      );

      setState(() {
        _leaveList.addAll(list);
        _page++;
        _hasMore = list.length >= 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  void _onFilterChanged(String value) {
    setState(() { _currentFilter = value; });
    _loadData();
  }

  void _navigateToApply() async {
    final result = await Get.to(() => const LeaveApplyPage());
    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('请假记录'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _isLoading && _leaveList.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: _leaveList.isEmpty
                        ? _buildEmptyState()
                        : _buildList(),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToApply,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _currentFilter == filter['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter['label']!),
              selected: isSelected,
              onSelected: (_) => _onFilterChanged(filter['value']!),
              selectedColor: AppColors.primary.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              backgroundColor: Colors.grey[100],
              side: BorderSide.none,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            '暂无请假记录',
            style: TextStyle(color: AppColors.textHint, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _navigateToApply,
            child: const Text('点击申请请假'),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _leaveList.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _leaveList.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildLeaveItem(_leaveList[index]);
      },
    );
  }

  Widget _buildLeaveItem(LeaveModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.leaveTypeText,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              _buildStatusBadge(item.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '申请时间: ${item.startDate} 至 ${item.endDate}',
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            '共 ${item.totalDays} 天',
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          if (item.reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '原因: ${item.reason}',
              style: const TextStyle(fontSize: 13, color: AppColors.textHint),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (item.status == 'REJECTED' && item.rejectReason != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.error, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '拒绝原因: ${item.rejectReason}',
                      style: const TextStyle(fontSize: 12, color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    switch (status) {
      case 'PENDING':
        color = AppColors.warning;
        text = '待审批';
        break;
      case 'APPROVED':
        color = AppColors.success;
        text = '已通过';
        break;
      case 'REJECTED':
        color = AppColors.error;
        text = '已拒绝';
        break;
      default:
        color = AppColors.textHint;
        text = '未知';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
    );
  }
}
