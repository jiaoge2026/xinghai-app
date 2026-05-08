import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/engineer_model.dart';
import '../../data/services/engineer_service.dart';
import '../providers/auth_provider.dart';
import 'attendance_page.dart';
import 'leave_list_page.dart';
import 'salary_page.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final EngineerService _engineerService = EngineerService();
  EngineerModel? _engineerInfo;
  bool _isLoading = true;
  int _currentStatus = AppConstants.engineerAccepting;

  @override
  void initState() {
    super.initState();
    _loadEngineerInfo();
  }

  Future<void> _loadEngineerInfo() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;

    if (userId == null) {
      setState(() { _isLoading = false; });
      return;
    }

    try {
      final engineer = await _engineerService.getDetail(userId);
      setState(() {
        _engineerInfo = engineer;
        _currentStatus = engineer.status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _toggleStatus() async {
    final newStatus = _currentStatus == AppConstants.engineerAccepting
        ? AppConstants.engineerPaused
        : AppConstants.engineerAccepting;

    setState(() { _isLoading = true; });

    try {
      await _engineerService.updateStatus(_engineerInfo!.id, newStatus);
      setState(() {
        _currentStatus = newStatus;
        _engineerInfo = _engineerInfo!.copyWith(status: newStatus);
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == AppConstants.engineerAccepting ? '已开启接单' : '已暂停接单'),
            backgroundColor: newStatus == AppConstants.engineerAccepting ? AppColors.success : AppColors.warning,
          ),
        );
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败：$e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('退出'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();
      Get.offAllNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('我的'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // 用户信息卡片
                  _buildUserInfoCard(),
                  const SizedBox(height: 12),
                  // 接单状态切换
                  _buildStatusCard(),
                  const SizedBox(height: 12),
                  // 统计数据
                  if (_engineerInfo != null) ...[
                    _buildStatsCard(),
                    const SizedBox(height: 12),
                  ],
                  // 功能菜单
                  _buildMenuCard(),
                  const SizedBox(height: 12),
                  // 退出登录按钮
                  _buildLogoutButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildUserInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              _engineerInfo?.name.substring(0, 1) ?? 'U',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _engineerInfo?.name ?? context.read<AuthProvider>().currentUser?.realName ?? '工程师',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            '工号: ${_engineerInfo?.id ?? context.read<AuthProvider>().currentUser?.id ?? '-'}',
            style: const TextStyle(fontSize: 13, color: AppColors.textHint),
          ),
          if (_engineerInfo?.phone != null) ...[
            const SizedBox(height: 4),
            Text(
              _engineerInfo!.phone!,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
          if (_engineerInfo?.skillTags != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: _engineerInfo!.skillTags!.split(',').map((tag) =>
                Chip(
                  label: Text(tag.trim(), style: const TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _currentStatus == AppConstants.engineerAccepting
                ? Icons.check_circle
                : Icons.pause_circle,
            color: _currentStatus == AppConstants.engineerAccepting
                ? AppColors.success
                : AppColors.warning,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '接单状态',
                  style: TextStyle(fontSize: 14, color: AppColors.textHint),
                ),
                Text(
                  _currentStatus == AppConstants.engineerAccepting ? '接单中' : '已暂停',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _currentStatus == AppConstants.engineerAccepting
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _currentStatus == AppConstants.engineerAccepting,
            activeColor: AppColors.success,
            onChanged: (_) => _toggleStatus(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildStatItem('今日工单', '${_engineerInfo!.todayWoCount ?? 0}', Icons.today),
          const SizedBox(width: 24),
          _buildStatItem('总工单', '${_engineerInfo!.totalWoCount ?? 0}', Icons.assignment),
          const SizedBox(width: 24),
          _buildStatItem(
            '好评率',
            _engineerInfo!.avgRating != null ? '${_engineerInfo!.avgRating!.toStringAsFixed(1)}' : '-',
            Icons.star,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
        ],
      ),
    );
  }

  Widget _buildMenuCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildMenuItem(Icons.event_busy, '我的请假', () => Get.to(() => const LeaveListPage())),
          const Divider(height: 1),
          _buildMenuItem(Icons.access_time, '考勤记录', () => Get.to(() => const AttendancePage())),
          const Divider(height: 1),
          _buildMenuItem(Icons.account_balance_wallet, '薪资明细', () => Get.to(() => const SalaryPage())),
          const Divider(height: 1),
          _buildMenuItem(Icons.history, '历史工单', () => Get.toNamed('/work-order/list')),
          const Divider(height: 1),
          _buildMenuItem(Icons.bar_chart, '工作统计', () {}),
          const Divider(height: 1),
          _buildMenuItem(Icons.person_outline, '个人信息编辑', () {}),
          const Divider(height: 1),
          _buildMenuItem(Icons.settings, '设置', () {}),
          const Divider(height: 1),
          _buildMenuItem(Icons.help_outline, '帮助与反馈', () {}),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _logout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.error,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: const Text('退出登录', style: TextStyle(fontSize: 16)),
      ),
    );
  }
}

extension on EngineerModel {
  EngineerModel copyWith({int? status}) {
    return EngineerModel(
      id: id,
      name: name,
      phone: phone,
      avatar: avatar,
      status: status ?? this.status,
      skillTags: skillTags,
      area: area,
      avgRating: avgRating,
      todayWoCount: todayWoCount,
      totalWoCount: totalWoCount,
    );
  }
}
