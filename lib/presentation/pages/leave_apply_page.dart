import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/leave_model.dart';
import '../../data/services/leave_service.dart';
import '../providers/auth_provider.dart';

class LeaveApplyPage extends StatefulWidget {
  const LeaveApplyPage({super.key});

  @override
  State<LeaveApplyPage> createState() => _LeaveApplyPageState();
}

class _LeaveApplyPageState extends State<LeaveApplyPage> {
  final LeaveService _service = LeaveService();
  final TextEditingController _reasonController = TextEditingController();

  String _selectedLeaveType = 'ANNUAL';
  DateTime? _startDate;
  DateTime? _endDate;
  double _totalDays = 0;
  bool _isSubmitting = false;
  LeaveBalanceModel? _balance;

  final List<Map<String, String>> _leaveTypes = [
    {'value': 'ANNUAL', 'label': '年假'},
    {'value': 'SICK', 'label': '病假'},
    {'value': 'PERSONAL', 'label': '事假'},
    {'value': 'MATERNITY', 'label': '产假'},
    {'value': 'PATERNITY', 'label': '陪产假'},
    {'value': 'MARRIAGE', 'label': '婚假'},
    {'value': 'BEREAVEMENT', 'label': '丧假'},
    {'value': 'OTHER', 'label': '其他'},
  ];

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    try {
      final balance = await _service.getLeaveBalance();
      setState(() { _balance = balance; });
    } catch (e) {
      // 忽略错误
    }
  }

  void _selectStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _calculateDays();
      });
    }
  }

  void _selectEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? now,
      firstDate: _startDate ?? now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _calculateDays();
      });
    }
  }

  void _calculateDays() {
    if (_startDate != null && _endDate != null) {
      final days = _endDate!.difference(_startDate!).inDays + 1;
      setState(() { _totalDays = days.toDouble(); });
    }
  }

  double _getAvailableBalance() {
    if (_balance == null) return 0;
    switch (_selectedLeaveType) {
      case 'ANNUAL':
        return _balance!.annualBalance;
      case 'SICK':
        return _balance!.sickBalance;
      case 'PERSONAL':
        return _balance!.personalBalance;
      default:
        return 999;
    }
  }

  bool _validate() {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择开始日期'), backgroundColor: AppColors.error),
      );
      return false;
    }
    if (_endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择结束日期'), backgroundColor: AppColors.error),
      );
      return false;
    }
    if (_totalDays <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请假天数必须大于0'), backgroundColor: AppColors.error),
      );
      return false;
    }
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入请假原因'), backgroundColor: AppColors.error),
      );
      return false;
    }
    if (_selectedLeaveType == 'ANNUAL' && _totalDays > _balance!.annualBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('年假余额不足，剩余 ${_balance!.annualBalance} 天'), backgroundColor: AppColors.error),
      );
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() { _isSubmitting = true; });

    try {
      final employeeId = context.read<AuthProvider>().currentUser!.id;
      await _service.apply(
        employeeId: employeeId,
        leaveType: _selectedLeaveType,
        startDate: _formatDate(_startDate!),
        endDate: _formatDate(_endDate!),
        totalDays: _totalDays,
        reason: _reasonController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请假申请已提交'), backgroundColor: AppColors.success),
        );
        Get.back(result: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('提交失败：$e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() { _isSubmitting = false; });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('申请请假'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLeaveTypeCard(),
            const SizedBox(height: 12),
            _buildDateCard(),
            const SizedBox(height: 12),
            _buildReasonCard(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveTypeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '请假类型',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _leaveTypes.map((type) {
              final isSelected = _selectedLeaveType == type['value'];
              return ChoiceChip(
                label: Text(type['label']!),
                selected: isSelected,
                onSelected: (_) {
                  setState(() { _selectedLeaveType = type['value']!; });
                },
                selectedColor: AppColors.primary.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                backgroundColor: Colors.grey[100],
                side: BorderSide.none,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _buildBalanceInfo(),
        ],
      ),
    );
  }

  Widget _buildBalanceInfo() {
    final balance = _getAvailableBalance();
    if (_selectedLeaveType == 'ANNUAL' || _selectedLeaveType == 'SICK' || _selectedLeaveType == 'PERSONAL') {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.info.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.info, size: 16),
            const SizedBox(width: 4),
            Text(
              '剩余 ${balance.toStringAsFixed(1)} 天可用',
              style: const TextStyle(fontSize: 12, color: AppColors.info),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDateCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '请假时间',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  label: '开始日期',
                  value: _startDate,
                  onTap: _selectStartDate,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward, color: AppColors.textHint),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDatePicker(
                  label: '结束日期',
                  value: _endDate,
                  onTap: _selectEndDate,
                ),
              ),
            ],
          ),
          if (_totalDays > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.access_time, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '共 $_totalDays 天',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.textHint, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                  ),
                  Text(
                    value != null ? _formatDate(value) : '请选择',
                    style: TextStyle(
                      fontSize: 14,
                      color: value != null ? AppColors.textPrimary : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '请假原因',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: '请输入请假原因...',
              hintStyle: TextStyle(color: AppColors.textHint),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
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
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text('提交申请', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
