import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/workflow_model.dart';
import '../../data/services/workflow_service.dart';

class ApprovalDetailPage extends StatefulWidget {
  final String instanceNo;

  const ApprovalDetailPage({super.key, required this.instanceNo});

  @override
  State<ApprovalDetailPage> createState() => _ApprovalDetailPageState();
}

class _ApprovalDetailPageState extends State<ApprovalDetailPage> {
  final WorkflowService _workflowService = WorkflowService();
  WorkflowDetailModel? _detail;
  bool _isLoading = true;
  bool _isOperating = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    try {
      final detail = await _workflowService.getInstanceDetail(widget.instanceNo);
      setState(() {
        _detail = detail;
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

  Future<void> _approve() async {
    if (_isOperating) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认审批'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('确定要通过此审批吗？'),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: '审批意见（可选）',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('通过'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isOperating = true);

    try {
      await _workflowService.approve(
        instanceId: _detail!.instance.id,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );
      setState(() => _isOperating = false);
      _commentController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('审批已通过'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadDetail();
      }
    } catch (e) {
      setState(() => _isOperating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败：$e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _reject() async {
    if (_isOperating) return;

    final comment = await showDialog<String>(
      context: context,
      builder: (context) {
        final textController = TextEditingController();
        return AlertDialog(
          title: const Text('驳回审批'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('请输入驳回原因：'),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: '驳回原因（必填）',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (textController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('请输入驳回原因'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, textController.text.trim());
              },
              child: const Text('驳回', style: TextStyle(color: AppColors.error)),
            ),
          ],
        );
      },
    );

    if (comment == null || comment.isEmpty) return;

    setState(() => _isOperating = true);

    try {
      await _workflowService.reject(
        instanceId: _detail!.instance.id,
        comment: comment,
      );
      setState(() => _isOperating = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已驳回'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadDetail();
      }
    } catch (e) {
      setState(() => _isOperating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败：$e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('撤回申请'),
        content: const Text('确定要撤回此申请吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('撤回'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isOperating = true);

    try {
      await _workflowService.cancel(_detail!.instance.id);
      setState(() => _isOperating = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已撤回'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadDetail();
      }
    } catch (e) {
      setState(() => _isOperating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败：$e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  bool get _canApprove {
    final instance = _detail?.instance;
    if (instance == null) return false;
    return instance.status == 1 || instance.status == 2;
  }

  bool get _isApplicant {
    return false;
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
          '审批详情',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_detail != null && _isApplicant && _canApprove)
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: _isOperating ? null : _cancel,
              tooltip: '撤回',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _detail == null
              ? _buildErrorState()
              : _buildContent(),
      bottomNavigationBar: _canApprove && !_isApplicant ? _buildActionBar() : null,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          const Text(
            '加载失败',
            style: TextStyle(fontSize: 16, color: AppColors.textHint),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadDetail,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final instance = _detail!.instance;
    final nodes = _detail!.nodes;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(instance),
          const SizedBox(height: 16),
          _buildBusinessDataCard(instance),
          const SizedBox(height: 16),
          _buildTimelineCard(nodes),
        ],
      ),
    );
  }

  Widget _buildInfoCard(WorkflowInstanceModel instance) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    instance.workflowName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _buildStatusTag(instance.status, instance.statusText),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('单号', instance.instanceNo),
            _buildInfoRow('类型', instance.businessType),
            _buildInfoRow('申请人', instance.applicantName),
            _buildInfoRow('申请时间', _formatTime(instance.applyTime)),
            if (instance.currentNode != null)
              _buildInfoRow('当前节点', instance.currentNode!),
            if (instance.currentApproverNames != null)
              _buildInfoRow('审批人', instance.currentApproverNames!),
            if (instance.completeTime != null)
              _buildInfoRow('完成时间', _formatTime(instance.completeTime!)),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessDataCard(WorkflowInstanceModel instance) {
    final businessData = instance.businessData;
    if (businessData == null || businessData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '关联业务数据',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...businessData.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        _formatFieldName(entry.key),
                        style: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value.toString(),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard(List<WorkflowNodeModel> nodes) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '审批流程',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (nodes.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    '暂无审批记录',
                    style: TextStyle(color: AppColors.textHint),
                  ),
                ),
              )
            else
              ...nodes.asMap().entries.map((entry) {
                final index = entry.key;
                final node = entry.value;
                final isLast = index == nodes.length - 1;
                return _buildTimelineNode(node, isLast);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineNode(WorkflowNodeModel node, bool isLast) {
    Color nodeColor;
    IconData nodeIcon;

    switch (node.approveStatus) {
      case 2:
        nodeColor = AppColors.success;
        nodeIcon = Icons.check_circle;
        break;
      case 3:
        nodeColor = AppColors.error;
        nodeIcon = Icons.cancel;
        break;
      case 4:
        nodeColor = AppColors.warning;
        nodeIcon = Icons.undo;
        break;
      default:
        nodeColor = AppColors.primary;
        nodeIcon = Icons.radio_button_checked;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Icon(nodeIcon, color: nodeColor, size: 20),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.divider,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: node.approveStatus <= 1
                    ? Border.all(color: AppColors.primary.withOpacity(0.3))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        node.nodeName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: node.approveStatus <= 1
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        node.statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: nodeColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (node.approverName != null)
                    _buildNodeRow(Icons.person, node.approverName!),
                  if (node.approveTime != null)
                    _buildNodeRow(Icons.access_time, _formatTime(node.approveTime!)),
                  if (node.comment != null && node.comment!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        node.comment!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isOperating ? null : _reject,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isOperating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('驳回'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isOperating ? null : _approve,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isOperating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('通过'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textHint,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textHint),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
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

  String _formatFieldName(String key) {
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}')
        .replaceAll('_', ' ')
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : '')
        .join(' ');
  }
}
