import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/opportunity_model.dart';
import '../../data/services/crm_service.dart';
import 'opportunity_form_page.dart';
import 'customer_follow_up_page.dart';

class OpportunityDetailPage extends StatefulWidget {
  const OpportunityDetailPage({super.key});

  @override
  State<OpportunityDetailPage> createState() => _OpportunityDetailPageState();
}

class _OpportunityDetailPageState extends State<OpportunityDetailPage> {
  late int _opportunityId;
  final CRMService _crmService = CRMService();

  OpportunityModel? _opportunity;
  List<CustomerFollowUpModel> _followUps = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _opportunityId = Get.arguments as int;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    try {
      final opportunity = await _crmService.getOpportunityDetail(_opportunityId);
      final followUps = await _crmService.getFollowUps(_opportunityId);
      setState(() {
        _opportunity = opportunity;
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

  Color _getStageColor(int stage) {
    switch (stage) {
      case 1:
        return AppColors.info;
      case 2:
        return AppColors.primary;
      case 3:
        return AppColors.warning;
      case 4:
        return Colors.purple;
      case 5:
        return AppColors.success;
      case 6:
        return AppColors.textHint;
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _showStagePicker() async {
    if (_opportunity == null) return;

    final stages = [
      {'value': 1, 'label': '新商机'},
      {'value': 2, 'label': '已Qualified'},
      {'value': 3, 'label': '提案'},
      {'value': 4, 'label': '谈判'},
      {'value': 5, 'label': '成交'},
      {'value': 6, 'label': '输单'},
    ];

    final result = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选择阶段',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...stages.map((s) => ListTile(
                  title: Text(s['label'] as String),
                  trailing: _opportunity!.stage == s['value']
                      ? const Icon(Icons.check, color: AppColors.success)
                      : null,
                  onTap: () => Navigator.pop(context, s['value']),
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (result != null && result != _opportunity!.stage) {
      await _updateStage(result);
    }
  }

  Future<void> _updateStage(int newStage) async {
    setState(() => _isSubmitting = true);
    try {
      await _crmService.updateOpportunityStage(_opportunityId, newStage);
      await _loadDetail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('阶段更新成功'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败：$e'), backgroundColor: AppColors.error),
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
        title: const Text('商机详情', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          if (_opportunity != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => Get.to(() => OpportunityFormPage(opportunity: _opportunity)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _opportunity == null
              ? const Center(child: Text('加载失败'))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBasicInfo(),
                            const SizedBox(height: 16),
                            _buildStageProgress(),
                            const SizedBox(height: 16),
                            _buildFollowUpSection(),
                          ],
                        ),
                      ),
                    ),
                    _buildBottomAction(),
                  ],
                ),
    );
  }

  Widget _buildBasicInfo() {
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
                Expanded(
                  child: Text(
                    _opportunity!.opportunityName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStageColor(_opportunity!.stage).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _opportunity!.stageText,
                    style: TextStyle(
                      fontSize: 14,
                      color: _getStageColor(_opportunity!.stage),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.business, '客户名称', _opportunity!.customerName),
            _buildInfoRow(Icons.person, '负责人', _opportunity!.employeeName),
            _buildInfoRow(
              Icons.attach_money,
              '预估金额',
              '¥${_opportunity!.estimatedAmount.toStringAsFixed(0)}',
              valueColor: AppColors.success,
            ),
            _buildInfoRow(
              Icons.percent,
              '概率',
              '${_opportunity!.probability}%',
              valueColor: Colors.orange,
            ),
            if (_opportunity!.source != null)
              _buildInfoRow(Icons.source, '来源', _opportunity!.source!),
            if (_opportunity!.expectedCloseDate != null)
              _buildInfoRow(Icons.event, '预计关闭日期', _opportunity!.expectedCloseDate!),
          ],
        ),
      ),
    );
  }

  Widget _buildStageProgress() {
    final stages = [
      {'label': '新商机', 'value': 1},
      {'label': 'Qualified', 'value': 2},
      {'label': '提案', 'value': 3},
      {'label': '谈判', 'value': 4},
      {'label': '成交', 'value': 5},
    ];

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '阶段进度',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(stages.length * 2 - 1, (index) {
                if (index.isOdd) {
                  return Expanded(
                    child: Container(
                      height: 2,
                      color: index ~/ 2 < _opportunity!.stage - 1
                          ? _getStageColor(_opportunity!.stage)
                          : AppColors.divider,
                    ),
                  );
                }
                final stageIndex = index ~/ 2;
                final stageValue = stages[stageIndex]['value'] as int;
                final isActive = stageValue <= _opportunity!.stage;
                return Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isActive ? _getStageColor(_opportunity!.stage) : AppColors.divider,
                    shape: BoxShape.circle,
                  ),
                  child: isActive
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                );
              }),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: stages.map((s) => Text(
                    s['label'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      color: (s['value'] as int) <= _opportunity!.stage
                          ? _getStageColor(_opportunity!.stage)
                          : AppColors.textHint,
                    ),
                  )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowUpSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '跟进记录',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                TextButton.icon(
                  onPressed: () => Get.to(() => CustomerFollowUpPage(opportunityId: _opportunityId)),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('新增'),
                ),
              ],
            ),
            if (_followUps.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    '暂无跟进记录',
                    style: TextStyle(color: AppColors.textHint, fontSize: 14),
                  ),
                ),
              )
            else
              ..._followUps.take(5).map((followUp) => _buildFollowUpItem(followUp)),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowUpItem(CustomerFollowUpModel followUp) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              _getFollowUpIcon(followUp.followUpType),
              size: 16,
              color: AppColors.info,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      followUp.followUpTypeText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      followUp.employeeName,
                      style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  followUp.content,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (followUp.followUpDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    followUp.followUpDate!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
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
              style: TextStyle(fontSize: 14, color: valueColor ?? AppColors.textPrimary),
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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Get.to(() => CustomerFollowUpPage(opportunityId: _opportunityId)),
                icon: const Icon(Icons.add),
                label: const Text('新增跟进'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.info,
                  side: const BorderSide(color: AppColors.info),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _showStagePicker,
                icon: const Icon(Icons.trending_up),
                label: const Text('推进阶段'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
