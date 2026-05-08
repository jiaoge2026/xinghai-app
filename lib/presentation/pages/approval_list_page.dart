import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/workflow_model.dart';
import '../../data/services/workflow_service.dart';
import 'approval_detail_page.dart';

class ApprovalListPage extends StatefulWidget {
  const ApprovalListPage({super.key});

  @override
  State<ApprovalListPage> createState() => _ApprovalListPageState();
}

class _ApprovalListPageState extends State<ApprovalListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final WorkflowService _workflowService = WorkflowService();
  final ScrollController _scrollController = ScrollController();

  List<WorkflowInstanceModel> _pendingList = [];
  List<WorkflowInstanceModel> _myApplicationList = [];
  bool _isLoadingPending = false;
  bool _isLoadingMyApp = false;
  bool _hasMorePending = true;
  bool _hasMoreMyApp = true;
  int _pagePending = 1;
  int _pageMyApp = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPending();
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
    if (_tabController.index == 0 && _pendingList.isEmpty) {
      _loadPending();
    } else if (_tabController.index == 1 && _myApplicationList.isEmpty) {
      _loadMyApplications();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_tabController.index == 0) {
        if (!_isLoadingPending && _hasMorePending) {
          _loadPending();
        }
      } else {
        if (!_isLoadingMyApp && _hasMoreMyApp) {
          _loadMyApplications();
        }
      }
    }
  }

  Future<void> _loadPending({bool refresh = false}) async {
    if (refresh) {
      _pagePending = 1;
      _hasMorePending = true;
    }

    if (_isLoadingPending || !_hasMorePending) return;

    setState(() => _isLoadingPending = true);

    try {
      final list = await _workflowService.getPendingApprovals(page: _pagePending);
      setState(() {
        if (refresh) {
          _pendingList = list;
        } else {
          _pendingList.addAll(list);
        }
        if (list.length < 20) {
          _hasMorePending = false;
        }
        _pagePending++;
        _isLoadingPending = false;
      });
    } catch (e) {
      setState(() => _isLoadingPending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败：$e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _loadMyApplications({bool refresh = false}) async {
    if (refresh) {
      _pageMyApp = 1;
      _hasMoreMyApp = true;
    }

    if (_isLoadingMyApp || !_hasMoreMyApp) return;

    setState(() => _isLoadingMyApp = true);

    try {
      final list = await _workflowService.getMyApplications(page: _pageMyApp);
      setState(() {
        if (refresh) {
          _myApplicationList = list;
        } else {
          _myApplicationList.addAll(list);
        }
        if (list.length < 20) {
          _hasMoreMyApp = false;
        }
        _pageMyApp++;
        _isLoadingMyApp = false;
      });
    } catch (e) {
      setState(() => _isLoadingMyApp = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败：$e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    if (_tabController.index == 0) {
      await _loadPending(refresh: true);
    } else {
      await _loadMyApplications(refresh: true);
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
          '审批中心',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '待我审批'),
            Tab(text: '我的申请'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingList(),
          _buildMyApplicationList(),
        ],
      ),
    );
  }

  Widget _buildPendingList() {
    if (_isLoadingPending && _pendingList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingList.isEmpty) {
      return _buildEmptyState('暂无待审批事项', '所有审批都已处理完毕');
    }

    return RefreshIndicator(
      onRefresh: () => _loadPending(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _pendingList.length + (_hasMorePending ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _pendingList.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildApprovalCard(_pendingList[index]);
        },
      ),
    );
  }

  Widget _buildMyApplicationList() {
    if (_isLoadingMyApp && _myApplicationList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myApplicationList.isEmpty) {
      return _buildEmptyState('暂无申请记录', '您还没有提交过任何申请');
    }

    return RefreshIndicator(
      onRefresh: () => _loadMyApplications(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _myApplicationList.length + (_hasMoreMyApp ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _myApplicationList.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildApplicationCard(_myApplicationList[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textHint,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textHint.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(WorkflowInstanceModel item) {
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
                  const Icon(Icons.person_outline, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    '申请人：${item.applicantName}',
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
            ],
          ),
        ),
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
