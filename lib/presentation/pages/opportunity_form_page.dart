import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/opportunity_model.dart';
import '../../data/services/crm_service.dart';

class OpportunityFormPage extends StatefulWidget {
  final OpportunityModel? opportunity;

  const OpportunityFormPage({super.key, this.opportunity});

  @override
  State<OpportunityFormPage> createState() => _OpportunityFormPageState();
}

class _OpportunityFormPageState extends State<OpportunityFormPage> {
  final CRMService _crmService = CRMService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _customerController;
  late TextEditingController _amountController;
  late TextEditingController _probabilityController;
  late TextEditingController _sourceController;

  int _stage = 1;
  DateTime? _expectedCloseDate;
  bool _isSubmitting = false;

  bool get _isEditing => widget.opportunity != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.opportunity?.opportunityName ?? '');
    _customerController = TextEditingController(text: widget.opportunity?.customerName ?? '');
    _amountController = TextEditingController(
      text: widget.opportunity?.estimatedAmount.toStringAsFixed(0) ?? '',
    );
    _probabilityController = TextEditingController(
      text: widget.opportunity?.probability.toString() ?? '10',
    );
    _sourceController = TextEditingController(text: widget.opportunity?.source ?? '');
    _stage = widget.opportunity?.stage ?? 1;
    if (widget.opportunity?.expectedCloseDate != null) {
      _expectedCloseDate = DateTime.tryParse(widget.opportunity!.expectedCloseDate!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customerController.dispose();
    _amountController.dispose();
    _probabilityController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedCloseDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _expectedCloseDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final data = {
        'opportunityName': _nameController.text.trim(),
        'customerName': _customerController.text.trim(),
        'estimatedAmount': double.parse(_amountController.text.trim()),
        'probability': int.parse(_probabilityController.text.trim()),
        'stage': _stage,
        if (_sourceController.text.trim().isNotEmpty) 'source': _sourceController.text.trim(),
        if (_expectedCloseDate != null)
          'expectedCloseDate': DateFormat('yyyy-MM-dd').format(_expectedCloseDate!),
      };

      if (_isEditing) {
        await _crmService.updateOpportunity(widget.opportunity!.id, data);
      } else {
        await _crmService.createOpportunity(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? '更新成功' : '创建成功'),
            backgroundColor: AppColors.success,
          ),
        );
        Get.back(result: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败：$e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
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
          _isEditing ? '编辑商机' : '新增商机',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormCard(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('基本信息'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameController,
              label: '商机名称',
              hint: '请输入商机名称',
              required: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _customerController,
              label: '客户名称',
              hint: '请输入客户名称',
              required: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _amountController,
                    label: '预估金额',
                    hint: '请输入金额',
                    required: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    prefixText: '¥ ',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _probabilityController,
                    label: '概率',
                    hint: '0-100',
                    required: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    suffixText: '%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _sourceController,
              label: '来源',
              hint: '请输入商机来源（可选）',
            ),
            const SizedBox(height: 16),
            _buildStageSelector(),
            const SizedBox(height: 16),
            _buildDateSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
    String? suffixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            if (required)
              const Text(' *', style: TextStyle(color: AppColors.error, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textHint),
            prefixText: prefixText,
            suffixText: suffixText,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          validator: required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入$label';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildStageSelector() {
    final stages = [
      {'value': 1, 'label': '新商机'},
      {'value': 2, 'label': '已Qualified'},
      {'value': 3, 'label': '提案'},
      {'value': 4, 'label': '谈判'},
      {'value': 5, 'label': '成交'},
      {'value': 6, 'label': '输单'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              '阶段',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            Text(' *', style: TextStyle(color: AppColors.error, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: stages.map((s) {
            final isSelected = _stage == s['value'];
            return ChoiceChip(
              label: Text(s['label'] as String),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _stage = s['value'] as int);
                }
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontSize: 13,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '预计关闭日期',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
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
                    _expectedCloseDate != null
                        ? DateFormat('yyyy-MM-dd').format(_expectedCloseDate!)
                        : '请选择日期（可选）',
                    style: TextStyle(
                      fontSize: 14,
                      color: _expectedCloseDate != null ? AppColors.textPrimary : AppColors.textHint,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today, size: 18, color: AppColors.textHint),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                _isEditing ? '保存' : '创建',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
