import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/workflow_model.dart';
import '../../data/services/workflow_service.dart';
import 'approval_detail_page.dart';

class MyApplicationPage extends StatefulWidget {
  const MyApplicationPage({super.key});

  @override
  State<MyApplicationPage> createState() => _MyApplicationPageState();
}

class _MyApplicationPageState extends State<MyApplicationPage> {
  final WorkflowService _workflowService = WorkflowService();
  final ScrollController _scrollController = ScrollController();

  List<WorkflowInstanceModel> _applications = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  int? _statusFilter;

  final List<Map<String, dynamic>> _statusOptions = [
    {'value': null, 'label': '全部'},
    {'value': 1, 'label': '待审批'},
    {'value': 2, 'label': '审批中'},
    {'value': 3, 'label': '已通过'},
    {'value': 4, 'label': '已驳回'},
    {'value': 5, 'label': '已撤回'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadApplications();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadApplications();
      }
    }
  }

  Future<void> _loadApplications({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
    }

    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final list = await _workflowService.getMyApplications(
        page: _page,
        status: _statusFilter,
      );
      setState(() {
        if (refresh) {
          _applications = list;
        } else {
          _applications.addAll(list);
        }
        if (list.length < 20) {
          _hasMore = false;
        }
        _page++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败：$e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadApplications(refresh: true);
  }

  void _showStatusFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '筛选状态',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _statusOptions.map((option) {
                final isSelected = _statusFilter == option['value'];
                return ChoiceChip(
                  label: Text(option['label']),
                  selected: isSelected,
                  onSelected: (selected) {
                    Navigator.pop(context);
                    if (selected) {
                      setState(() {
                        _statusFilter = option['value'];
                      });
                      _loadApplications(refresh: true);
                    }
                  },
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusLabel() {
    final option = _statusOptions.firstWhere(
      (o) => o['value'] == _statusFilter,
      orElse: () => {'label': '全部'},
    );
    return option['label'];
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
          '我的申请',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showStatusFilter,
            tooltip: '筛选',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_statusFilter != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.primary.withOpacity(0.1),
              child: Row(
                children: [
                  Text(
                    '当前筛选：${_getStatusLabel()}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() => _statusFilter = null);
                      _loadApplications(refresh: true);
                    },
                    child: const Text('清除'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading && _applications.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _applications.isEmpty
                    ? _buildEmptyState()
                    : _buildApplicationList(),
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
            Icons.inbox_outlined,
            size: 80,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无申请记录',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _statusFilter != null ? '当前筛选条件下没有申请记录' : '您还没有提交过任何申请',
            style: TextStyle(
              color: AppColors.textHint.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationList() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _applications.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _applications.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildApplicationCard(_applications[index]);
        },
      ),
    );
  }

  Widget _buildApplicationCard(WorkflowInstanceModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Get.to(() => ApprovalDetailPage(instanceNo: item.instanceNo));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.workflowName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  _buildStatusTag(item.status, item.statusText),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.tag, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    item.instanceNo,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.category, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    '类型：${item.businessType}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    '申请时间：${_formatTime(item.applyTime)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (item.currentNode != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.flag, size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      '当前节点：${item.currentNode}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
              if (item.currentApproverNames != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.supervisor_account, size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '审批人：${item.currentApproverNames}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTag(int status, String text) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 1:
      case 2:
        bgColor = AppColors.warning.withOpacity(0.1);
        textColor = AppColors.warning;
        break;
      case 3:
        bgColor = AppColors.success.withOpacity(0.1);
        textColor = AppColors.success;
        break;
      case 4:
      case 5:
      case 6:
        bgColor = AppColors.error.withOpacity(0.1);
        textColor = AppColors.error;
        break;
      default:
        bgColor = AppColors.textHint.withOpacity(0.1);
        textColor = AppColors.textHint;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
