import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/project_model.dart';
import '../../data/services/project_service.dart';

class ProjectListPage extends StatefulWidget {
  const ProjectListPage({super.key});

  @override
  State<ProjectListPage> createState() => _ProjectListPageState();
}

class _ProjectListPageState extends State<ProjectListPage> {
  final ProjectService _projectService = ProjectService();
  final ScrollController _scrollController = ScrollController();

  List<ProjectModel> _projects = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadProjects(refresh: true);
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
        _loadProjects();
      }
    }
  }

  Future<void> _loadProjects({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _page = 1;
      _hasMore = true;
    }

    if (!_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final newProjects = await _projectService.getPage(
        page: _page,
        pageSize: _pageSize,
      );

      setState(() {
        if (refresh) {
          _projects = newProjects;
        } else {
          _projects.addAll(newProjects);
        }
        _hasMore = newProjects.length >= _pageSize;
        _page++;
      });
    } catch (e) {
      Get.snackbar('错误', '加载项目列表失败: $e',
          backgroundColor: AppColors.error, colorText: Colors.white);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    await _loadProjects(refresh: true);
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return AppColors.statusInProgress;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.statusCompleted;
      case 4:
        return AppColors.statusCancelled;
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
          '项目列表',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: _projects.isEmpty && !_isLoading
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _projects.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _projects.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return _buildProjectCard(_projects[index]);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_outlined, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            '暂无项目',
            style: TextStyle(color: AppColors.textHint, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(ProjectModel project) {
    final currencyFormat = NumberFormat.currency(symbol: '¥');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // TODO: 跳转到项目详情
          Get.snackbar('提示', '项目详情功能开发中',
              backgroundColor: AppColors.info, colorText: Colors.white);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(project.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      project.statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(project.status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.numbers, '项目编号', project.projectNo),
              const SizedBox(height: 4),
              if (project.customerName != null)
                _buildInfoRow(Icons.person_outline, '客户名称', project.customerName!),
              const SizedBox(height: 4),
              if (project.contractAmount != null)
                _buildInfoRow(
                  Icons.money_outlined,
                  '合同金额',
                  currencyFormat.format(project.contractAmount),
                ),
              const SizedBox(height: 4),
              if (project.signDate != null)
                _buildInfoRow(Icons.calendar_today_outlined, '签订日期', project.signDate!),
              if (project.workOrderCount != null) ...[
                const SizedBox(height: 4),
                _buildInfoRow(
                  Icons.assignment_outlined,
                  '工单数量',
                  '${project.workOrderCount} 单',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textHint),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textHint,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
