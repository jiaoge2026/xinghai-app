import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/sales_service.dart';

class ProjectOrderDetailPage extends StatefulWidget {
  const ProjectOrderDetailPage({super.key});

  @override
  State<ProjectOrderDetailPage> createState() => _ProjectOrderDetailPageState();
}

class _ProjectOrderDetailPageState extends State<ProjectOrderDetailPage> {
  final SalesService _svc = SalesService();
  final int orderId = Get.arguments as int;

  Map<String, dynamic>? _order;
  bool _loading = true;
  String? _error;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _svc.getProjectOrderById(orderId);
      setState(() { _order = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _confirm() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认订单'),
        content: Text('确认工程订单 ${_order?['orderNo'] ?? orderId}？\n\n确认后将：\n① 扣减成品库存\n② 生成应收款记录\n③ 如需安装，自动创建FSM工单'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() { _confirming = true; });
    try {
      await _svc.confirmProjectOrder(orderId);
      Get.snackbar('成功', '订单已确认', backgroundColor: AppColors.success);
      _load(); // 刷新状态
    } catch (e) {
      Get.snackbar('错误', '确认失败: $e', backgroundColor: AppColors.error);
    } finally {
      setState(() { _confirming = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('工程订单详情'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('$_error', style: const TextStyle(color: Colors.red)))
              : _buildContent(),
      bottomNavigationBar: _order != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildContent() {
    final o = _order!;
    final status = o['status']?.toString() ?? '';
    final canConfirm = status == '草稿' || status == '待确认';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 状态标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _statusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(status, style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),

          // 订单基本信息
          _card([
            _row('订单编号', o['orderNo'] ?? '-'),
            _divider(),
            _row('客户', o['customerName'] ?? '-'),
            _divider(),
            _row('订单金额', '¥${o['totalAmount'] ?? 0}'),
            _divider(),
            _row('订单日期', o['orderDate'] ?? o['confirmDate'] ?? '-'),
            if (o['confirmDate'] != null) ...[_divider(), _row('确认日期', o['confirmDate'])]),
            _divider(),
            _row('销售员', o['salesman'] ?? o['salesmanName'] ?? '-'),
            if (o['remark'] != null && o['remark'].toString().isNotEmpty) ...[
              _divider(),
              _row('备注', o['remark']),
            ],
          ]),

          const SizedBox(height: 12),

          // FSM工单信息
          if (o['fsmWorkOrderId'] != null)
            _card([
              const Text('FSM工单', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _row('工单ID', '${o['fsmWorkOrderId']}'),
              _divider(),
              _row('工单状态', o['fsmOrderStatus'] ?? '-'),
            ]),

          const SizedBox(height: 12),

          // 应收款信息
          if (o['requireFsm'] != null)
            _card([
              const Text('安装需求', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _row('需要安装', o['requireFsm'] == 1 ? '是' : '否'),
            ]),
        ],
      ),
    );
  }

  Widget? _buildBottomBar() {
    final status = _order?['status']?.toString() ?? '';
    final canConfirm = status == '草稿' || status == '待确认';
    if (!canConfirm) return null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _confirming ? null : _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _confirming
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('确认订单', style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(children: children),
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary)),
        Flexible(child: Text(value, textAlign: TextAlign.right)),
      ],
    ),
  );

  Widget _divider() => const Divider(height: 16);

  Color _statusColor(String status) {
    switch (status) {
      case '草稿': return Colors.orange;
      case '待确认': return Colors.blue;
      case '已确认': return Colors.green;
      case '已取消': return Colors.grey;
      default: return AppColors.textSecondary;
    }
  }
}
