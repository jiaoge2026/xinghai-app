import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/opportunity_model.dart';
import '../../data/services/crm_service.dart';

class CustomerFollowUpPage extends StatefulWidget {
  final int? opportunityId;
  final int? customerId;
  final String? customerName;

  const CustomerFollowUpPage({
    super.key,
    this.opportunityId,
    this.customerId,
    this.customerName,
  });

  @override
  State<CustomerFollowUpPage> createState() => _CustomerFollowUpPageState();
}

class _CustomerFollowUpPageState extends State<CustomerFollowUpPage> {
  final CRMService _crmService = CRMService();

  List<CustomerFollowUpModel> _followUps = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadFollowUps();
  }

  Future<void> _loadFollowUps() async {
    setState(() => _isLoading = true);
    try {
      final followUps = await _crmService.getFollowUps(
        widget.opportunityId ?? widget.customerId ?? 0,
      );
      setState(() {
        _followUps = followUps;
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

  Future<void> _showAddFollowUpDialog() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _AddFollowUpSheet(
        opportunityId: widget.opportunityId,
        customerId: widget.customerId,
        customerName: widget.customerName,
      ),
    );

    if (result == true) {
      await _loadFollowUps();
    }
  }

  IconData _getFollowUpIcon(int type) {
    switch (type) {
      case 1:
        return Icons.phone;
      case 2:
        return Icons.person_pin_circle;
      case 3:
        return Icons.chat;
      case 4:
        return Icons.email;
      default:
        return Icons.note;
    }
  }

  Color _getFollowUpColor(int type) {
    switch (type) {
      case 1:
        return AppColors.success;
      case 2:
        return AppColors.primary;
      case 3:
        return AppColors.info;
      case 4:
        return Colors.purple;
      default:
        return AppColors.textHint;
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
        title: Text(
          widget.customerName ?? '客户跟进',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _followUps.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadFollowUps,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _followUps.length,
                    itemBuilder: (context, index) => _buildFollowUpCard(_followUps[index]),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFollowUpDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFollowUpCard(CustomerFollowUpModel followUp) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getFollowUpColor(followUp.followUpType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getFollowUpIcon(followUp.followUpType),
                    size: 20,
                    color: _getFollowUpColor(followUp.followUpType),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        followUp.followUpTypeText,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        followUp.employeeName,
                        style: const TextStyle(fontSize: 13, color: AppColors.textHint),
                      ),
                    ],
                  ),
                ),
                if (followUp.followUpDate != null)
                  Text(
                    followUp.followUpDate!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              followUp.content,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            if (followUp.nextPlanDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 14, color: AppColors.info),
                  const SizedBox(width: 4),
                  Text(
                    '下次计划: ${followUp.nextPlanDate}',
                    style: const TextStyle(fontSize: 12, color: AppColors.info),
                  ),
                ],
              ),
            ],
            if (followUp.followUpResult != null && followUp.followUpResult!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '跟进结果: ${followUp.followUpResult}',
                        style: const TextStyle(fontSize: 12, color: AppColors.success),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
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
            Icons.history,
            size: 80,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无跟进记录',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击右下角按钮新增跟进',
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

class _AddFollowUpSheet extends StatefulWidget {
  final int? opportunityId;
  final int? customerId;
  final String? customerName;

  const _AddFollowUpSheet({
    this.opportunityId,
    this.customerId,
    this.customerName,
  });

  @override
  State<_AddFollowUpSheet> createState() => _AddFollowUpSheetState();
}

class _AddFollowUpSheetState extends State<_AddFollowUpSheet> {
  final CRMService _crmService = CRMService();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _resultController = TextEditingController();

  int _followUpType = 1;
  DateTime? _nextPlanDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _contentController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextPlanDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _nextPlanDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写跟进内容'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final data = {
        'content': _contentController.text.trim(),
        'followUpType': _followUpType,
        if (_resultController.text.trim().isNotEmpty)
          'followUpResult': _resultController.text.trim(),
        if (_nextPlanDate != null)
          'nextPlanDate': DateFormat('yyyy-MM-dd').format(_nextPlanDate!),
        if (widget.opportunityId != null) 'opportunityId': widget.opportunityId,
        if (widget.customerId != null) 'customerId': widget.customerId,
      };

      await _crmService.addFollowUp(data);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('添加成功'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败：$e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '新增跟进记录',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            const Text('跟进方式', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildTypeChip(1, Icons.phone, '电话'),
                _buildTypeChip(2, Icons.person_pin_circle, '拜访'),
                _buildTypeChip(3, Icons.chat, '微信'),
                _buildTypeChip(4, Icons.email, '邮件'),
              ],
            ),
            const SizedBox(height: 16),
            const Text('跟进内容', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '请输入跟进内容',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 16),
            const Text('跟进结果（可选）', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _resultController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: '请输入跟进结果',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 16),
            const Text('下次计划日期（可选）', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _nextPlanDate != null
                            ? DateFormat('yyyy-MM-dd').format(_nextPlanDate!)
                            : '请选择日期',
                        style: TextStyle(
                          fontSize: 14,
                          color: _nextPlanDate != null ? AppColors.textPrimary : AppColors.textHint,
                        ),
                      ),
                    ),
                    const Icon(Icons.calendar_today, size: 18, color: AppColors.textHint),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('提交'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(int type, IconData icon, String label) {
    final isSelected = _followUpType == type;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? AppColors.primary : AppColors.textHint),
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _followUpType = type);
        }
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
    );
  }
}
