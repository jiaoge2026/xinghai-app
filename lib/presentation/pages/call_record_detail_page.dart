import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/call_record_model.dart';
import '../../data/services/call_center_service.dart';

class CallRecordDetailPage extends StatefulWidget {
  const CallRecordDetailPage({super.key});

  @override
  State<CallRecordDetailPage> createState() => _CallRecordDetailPageState();
}

class _CallRecordDetailPageState extends State<CallRecordDetailPage> {
  late int _recordId;
  final CallCenterService _callCenterService = CallCenterService();
  final TextEditingController _remarkController = TextEditingController();

  CallRecordModel? _record;
  bool _isLoading = true;
  bool _isSubmitting = false;

  String? _selectedAssociatedType;
  int? _selectedAssociatedId;

  @override
  void initState() {
    super.initState();
    _recordId = Get.arguments as int;
    _loadDetail();
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    try {
      final record = await _callCenterService.getCallRecordDetail(_recordId);
      setState(() {
        _record = record;
        _remarkController.text = record.processRemark ?? '';
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

  Future<void> _processRecord() async {
    if (_remarkController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写处理备注'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _callCenterService.processCallRecord(
        id: _recordId,
        remark: _remarkController.text.trim(),
        associatedType: _selectedAssociatedType,
        associatedId: _selectedAssociatedId,
      );

      await _loadDetail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('处理成功'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('处理失败：$e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return AppColors.warning;
      case 2:
        return AppColors.info;
      case 3:
        return AppColors.success;
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
        title: const Text('来电详情', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _record == null
              ? const Center(child: Text('加载失败'))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCallInfoCard(),
                            const SizedBox(height: 16),
                            if (_record!.customerName != null) ...[
                              _buildCustomerInfoCard(),
                              const SizedBox(height: 16),
                            ],
                            _buildProcessSection(),
                          ],
                        ),
                      ),
                    ),
                    if (_record!.status != 3) _buildBottomAction(),
                  ],
                ),
    );
  }

  Widget _buildCallInfoCard() {
    return Card(
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (_record!.callType == 1 ? AppColors.success : AppColors.info).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _record!.callType == 1 ? Icons.call_received : Icons.call_made,
                    color: _record!.callType == 1 ? AppColors.success : AppColors.info,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _record!.callTypeText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _record!.callType == 1 ? AppColors.success : AppColors.info,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_record!.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _record!.statusText,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusColor(_record!.status),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.phone, '来电号码', _record!.callerNumber),
            if (_record!.callTime != null)
              _buildInfoRow(Icons.access_time, '来电时间', _record!.callTime!),
            _buildInfoRow(Icons.timer, '通话时长', _record!.formattedDuration),
            _buildInfoRow(Icons.tag, '会话ID', _record!.callId),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '客户信息',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.person, '客户名称', _record!.customerName ?? '-'),
            if (_record!.associatedType != null)
              _buildInfoRow(Icons.link, '关联类型', _record!.associatedType!),
            if (_record!.associatedId != null)
              _buildInfoRow(Icons.tag, '关联ID', '${_record!.associatedId}'),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '关联操作',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            _buildAssociatedTypeSelector(),
            const SizedBox(height: 16),
            const Text(
              '处理备注',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _remarkController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '请输入处理备注',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssociatedTypeSelector() {
    final types = [
      {'value': 'WORK_ORDER', 'label': '工单'},
      {'value': 'PROJECT', 'label': '项目'},
      {'value': 'OPPORTUNITY', 'label': '商机'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '关联类型（可选）',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: types.map((t) {
            final isSelected = _selectedAssociatedType == t['value'];
            return ChoiceChip(
              label: Text(t['label'] as String),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedAssociatedType = selected ? t['value'] as String : null;
                  _selectedAssociatedId = null;
                });
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            );
          }).toList(),
        ),
        if (_selectedAssociatedType != null) ...[
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: '请输入关联ID',
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              suffixIcon: IconButton(
                icon: const Icon(Icons.check, color: AppColors.primary),
                onPressed: () {
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              _selectedAssociatedId = int.tryParse(value);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textHint),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 14, color: AppColors.textHint),
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

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _processRecord,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
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
                : const Text(
                    '标记已处理',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }
}
