import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_util.dart';
import '../../data/models/work_order_model.dart';
import '../providers/work_order_provider.dart';
import '../widgets/status_badge.dart';

class WorkOrderDetailPage extends StatefulWidget {
  const WorkOrderDetailPage({super.key});

  @override
  State<WorkOrderDetailPage> createState() => _WorkOrderDetailPageState();
}

class _WorkOrderDetailPageState extends State<WorkOrderDetailPage> {
  late int _workOrderId;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _workOrderId = Get.arguments as int;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkOrderProvider>().loadWorkOrderDetail(_workOrderId);
    });
  }

  Future<void> _updateStatus(int newStatus, {String? remark}) async {
    if (_isUpdating) return;

    setState(() { _isUpdating = true; });

    final woProvider = context.read<WorkOrderProvider>();
    final success = await woProvider.updateStatus(_workOrderId, newStatus, remark: remark);

    setState(() { _isUpdating = false; });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('状态已更新为：${AppColors.getStatusText(newStatus)}'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(woProvider.error ?? '更新失败'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showStatusActionSheet(WorkOrderModel wo) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _StatusActionSheet(
        currentStatus: wo.status,
        onStatusSelected: (status) {
          Navigator.pop(context);
          if (status == AppConstants.statusCompleted) {
            Get.toNamed('/work-order/complete', arguments: wo.id);
          } else {
            _updateStatus(status);
          }
        },
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
        title: const Text('工单详情'),
        elevation: 0,
      ),
      body: Consumer<WorkOrderProvider>(
        builder: (context, woProvider, child) {
          if (woProvider.isLoading && woProvider.currentWorkOrder == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final wo = woProvider.currentWorkOrder;
          if (wo == null) {
            return const Center(child: Text('工单不存在'));
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 状态操作卡片
                      _buildStatusCard(wo),
                      const SizedBox(height: 12),
                      // 客户信息
                      _buildSection('客户信息', [
                        _buildInfoRow('客户姓名', wo.customerName ?? '-'),
                        _buildInfoRow('联系电话', wo.customerPhone ?? '-'),
                        _buildInfoRow('服务地址', wo.customerAddress ?? '-'),
                      ]),
                      const SizedBox(height: 12),
                      // 设备信息
                      _buildSection('设备信息', [
                        _buildInfoRow('设备类型', wo.applianceType ?? '-'),
                        _buildInfoRow('品牌', wo.applianceBrand ?? '-'),
                        _buildInfoRow('型号', wo.applianceModel ?? '-'),
                        _buildInfoRow('故障描述', wo.faultDesc ?? '-'),
                      ]),
                      const SizedBox(height: 12),
                      // 服务信息
                      _buildSection('服务信息', [
                        _buildInfoRow('工单编号', wo.woNo),
                        _buildInfoRow('服务类型', wo.serviceType ?? '-'),
                        _buildInfoRow('预约时间', '${wo.scheduledDate ?? '-'} ${wo.scheduledTimeSlot ?? ''}'),
                        _buildInfoRow('创建时间', wo.createdAt != null ? DateUtil.formatDateTime(wo.createdAt!) : '-'),
                      ]),
                      // 工程师信息（已派单后显示）
                      if (wo.engineerId != null) ...[
                        const SizedBox(height: 12),
                        _buildEngineerSection(wo),
                      ],
                      // 完工历史记录
                      if (wo.status == AppConstants.statusCompleted || wo.status == AppConstants.statusCancelled) ...[
                        const SizedBox(height: 12),
                        _buildHistorySection(wo),
                      ],
                      if (wo.parts != null && wo.parts!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildPartsSection(wo.parts!),
                      ],
                      if (wo.remark != null && wo.remark!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildSection('备注', [
                          _buildInfoRow('备注', wo.remark!),
                        ]),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
              // 底部状态按钮
              _buildBottomButtons(wo),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(WorkOrderModel wo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getStatusColor(wo.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getStatusColor(wo.status).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(wo.status),
            color: AppColors.getStatusColor(wo.status),
            size: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppColors.getStatusText(wo.status),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getStatusColor(wo.status),
                  ),
                ),
                if (wo.engineerName != null)
                  Text(
                    '工程师：${wo.engineerName}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          StatusBadge(status: wo.status),
        ],
      ),
    );
  }

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 1: return Icons.hourglass_empty;
      case 2: return Icons.assignment_turned_in;
      case 3: return Icons.engineering;
      case 4: return Icons.check_circle;
      case 5: return Icons.cancel;
      default: return Icons.help;
    }
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppColors.textHint),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartsSection(List<PartModel> parts) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              '配件清单',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
          const Divider(height: 1),
          ...parts.map((p) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(child: Text(p.name, style: const TextStyle(fontSize: 14))),
                Text('x${p.quantity}', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                if (p.unitPrice != null) ...[
                  const SizedBox(width: 16),
                  Text('¥${p.unitPrice!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: AppColors.error)),
                ],
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildEngineerSection(WorkOrderModel wo) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              '工程师信息',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
          const Divider(height: 1),
          _buildInfoRow('工程师姓名', wo.engineerName ?? '-'),
          if (wo.status == AppConstants.statusInProgress || wo.status == AppConstants.statusCompleted)
            _buildInfoRow('到达时间', wo.updatedAt != null ? DateUtil.formatDateTime(wo.updatedAt!) : '处理中'),
        ],
      ),
    );
  }

  Widget _buildHistorySection(WorkOrderModel wo) {
    final historyItems = <Map<String, String>>[];

    historyItems.add({
      'status': '已创建',
      'time': wo.createdAt != null ? DateUtil.formatDateTime(wo.createdAt!) : '-',
      'remark': '工单已创建',
    });

    if (wo.engineerId != null) {
      historyItems.add({
        'status': '已派单',
        'time': wo.updatedAt != null ? DateUtil.formatDateTime(wo.updatedAt!) : '-',
        'remark': '分配工程师：${wo.engineerName ?? "-"}',
      });
    }

    if (wo.status == AppConstants.statusCompleted) {
      historyItems.add({
        'status': '已完成',
        'time': wo.updatedAt != null ? DateUtil.formatDateTime(wo.updatedAt!) : '-',
        'remark': wo.remark ?? '工单已完成',
      });
    } else if (wo.status == AppConstants.statusCancelled) {
      historyItems.add({
        'status': '已取消',
        'time': wo.updatedAt != null ? DateUtil.formatDateTime(wo.updatedAt!) : '-',
        'remark': wo.remark ?? '工单已取消',
      });
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              '完工历史记录',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
          const Divider(height: 1),
          ...historyItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: index < historyItems.length - 1
                    ? const Border(
                        bottom: BorderSide(color: AppColors.divider, width: 1),
                      )
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 5, right: 12),
                    decoration: BoxDecoration(
                      color: AppColors.getStatusColor(wo.status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['status'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['time'] ?? '',
                          style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                        ),
                        if (item['remark'] != null && item['remark'] != '-') ...[
                          const SizedBox(height: 2),
                          Text(
                            item['remark']!,
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(WorkOrderModel wo) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 待派单状态：显示提示
            if (wo.status == AppConstants.statusPending)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.statusPending.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '等待派单中...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.statusPending,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            // 已派单状态：显示"到达现场"按钮
            if (wo.status == AppConstants.statusAssigned) ...[
              Expanded(
                child: _buildActionButton(
                  '到达现场',
                  Icons.location_on,
                  AppColors.statusInProgress,
                  () => _updateStatus(AppConstants.statusInProgress, remark: '已到达现场'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  '取消',
                  Icons.cancel_outlined,
                  AppColors.statusCancelled,
                  () => _updateStatus(AppConstants.statusCancelled, remark: '客户取消'),
                ),
              ),
            ],
            // 进行中状态：显示"申请配件"和"申请延期"按钮
            if (wo.status == AppConstants.statusInProgress) ...[
              Expanded(
                child: _buildActionButton(
                  '申请配件',
                  Icons.inventory,
                  AppColors.warning,
                  () => _showApplyPartsDialog(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  '申请延期',
                  Icons.schedule,
                  AppColors.info,
                  () => _showApplyDelayDialog(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  '完工登记',
                  Icons.done_all,
                  AppColors.statusCompleted,
                  () => Get.toNamed('/work-order/complete', arguments: wo.id),
                ),
              ),
            ],
            // 已完成或已取消状态：显示返回按钮
            if (wo.status == AppConstants.statusCompleted || wo.status == AppConstants.statusCancelled)
              Expanded(
                child: _buildActionButton(
                  '返回',
                  Icons.arrow_back,
                  AppColors.textHint,
                  () => Get.back(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showApplyPartsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('申请配件'),
        content: const Text('配件申请功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showApplyDelayDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('申请延期'),
        content: const Text('延期申请功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: _isUpdating ? null : onPressed,
      icon: Icon(icon, size: 20),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    );
  }
}

class _StatusActionSheet extends StatelessWidget {
  final int currentStatus;
  final Function(int) onStatusSelected;

  const _StatusActionSheet({required this.currentStatus, required this.onStatusSelected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('变更工单状态', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          if (currentStatus == AppConstants.statusAssigned)
            _buildOption('接单', AppConstants.statusInProgress, Icons.check_circle, AppColors.statusInProgress),
          if (currentStatus == AppConstants.statusInProgress)
            _buildOption('完工', AppConstants.statusCompleted, Icons.done_all, AppColors.statusCompleted),
          _buildOption('取消工单', AppConstants.statusCancelled, Icons.cancel, AppColors.statusCancelled),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(String text, int status, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(text, style: TextStyle(color: color)),
      onTap: () => onStatusSelected(status),
    );
  }
}
