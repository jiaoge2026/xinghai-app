import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/work_order_model.dart';
import '../providers/work_order_provider.dart';

class WorkOrderCompletePage extends StatefulWidget {
  const WorkOrderCompletePage({super.key});

  @override
  State<WorkOrderCompletePage> createState() => _WorkOrderCompletePageState();
}

class _WorkOrderCompletePageState extends State<WorkOrderCompletePage> {
  final _formKey = GlobalKey<FormState>();
  final _workHoursController = TextEditingController();
  final _travelFeeController = TextEditingController();
  final _remarkController = TextEditingController();
  final List<PartModel> _selectedParts = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _workHoursController.dispose();
    _travelFeeController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() { _isSubmitting = true; });

    final woProvider = context.read<WorkOrderProvider>();
    final workOrderId = Get.arguments as int;

    final success = await woProvider.completeWorkOrder(
      id: workOrderId,
      workHours: double.parse(_workHoursController.text),
      travelFee: double.parse(_travelFeeController.text),
      materialFee: _selectedParts.fold(0.0, (sum, p) => sum + (p.unitPrice ?? 0) * p.quantity),
      remark: _remarkController.text.isEmpty ? null : _remarkController.text,
    );

    setState(() { _isSubmitting = false; });

    if (success) {
      Get.back();
      Get.back();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('完工登记成功'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(woProvider.error ?? '完工登记失败'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showAddPartDialog() {
    final nameController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加配件'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '配件名称', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyController,
                    decoration: const InputDecoration(labelText: '数量', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: '单价', border: OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              setState(() {
                _selectedParts.add(PartModel(
                  id: DateTime.now().millisecondsSinceEpoch,
                  name: nameController.text,
                  quantity: int.tryParse(qtyController.text) ?? 1,
                  unitPrice: double.tryParse(priceController.text),
                ));
              });
              Navigator.pop(context);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalMaterialFee = _selectedParts.fold(0.0, (sum, p) => sum + (p.unitPrice ?? 0) * p.quantity);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('完工登记'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 工时信息卡片
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '工时信息',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    // 工时输入
                    TextFormField(
                      controller: _workHoursController,
                      decoration: InputDecoration(
                        labelText: '工时（小时）',
                        hintText: '请输入实际工时',
                        prefixIcon: const Icon(Icons.timer_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) return '请输入工时';
                        final hours = double.tryParse(value);
                        if (hours == null || hours <= 0) return '请输入有效工时';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // 交通费输入
                    TextFormField(
                      controller: _travelFeeController,
                      decoration: InputDecoration(
                        labelText: '交通费（元）',
                        hintText: '请输入交通费',
                        prefixIcon: const Icon(Icons.directions_car_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) return '请输入交通费';
                        final fee = double.tryParse(value);
                        if (fee == null || fee < 0) return '请输入有效金额';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // 配件列表
              Container(
                width: double.infinity,
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
                        const Text(
                          '配件清单',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        TextButton.icon(
                          onPressed: _showAddPartDialog,
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('添加配件'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                        ),
                      ],
                    ),
                    if (_selectedParts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text('暂无配件', style: TextStyle(color: AppColors.textHint)),
                        ),
                      )
                    else
                      ..._selectedParts.asMap().entries.map((entry) {
                        final index = entry.key;
                        final part = entry.value;
                        return Dismissible(
                          key: Key('part_$index'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            color: AppColors.error,
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) {
                            setState(() { _selectedParts.removeAt(index); });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: AppColors.divider)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(part.name, style: const TextStyle(fontSize: 14)),
                                      Text(
                                        '¥${part.unitPrice?.toStringAsFixed(2) ?? '0.00'} x ${part.quantity}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '¥${((part.unitPrice ?? 0) * part.quantity).toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.error),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    if (_selectedParts.isNotEmpty) ...[
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('配件费用合计', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          Text(
                            '¥${totalMaterialFee.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.error),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // 备注输入
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '备注信息',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _remarkController,
                      decoration: InputDecoration(
                        hintText: '请输入备注信息（可选）',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // 提交按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                      : const Text('提交完工', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
