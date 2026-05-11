import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/member_model.dart';
import '../../data/services/member_service.dart';
import '../../data/services/coupon_service.dart';
import 'point_record_page.dart';
import 'coupon_list_page.dart';

class MemberDetailPage extends StatefulWidget {
  final int memberId;

  const MemberDetailPage({super.key, required this.memberId});

  @override
  State<MemberDetailPage> createState() => _MemberDetailPageState();
}

class _MemberDetailPageState extends State<MemberDetailPage> {
  final MemberService _memberService = MemberService();
  final CouponService _couponService = CouponService();
  
  MemberModel? _member;
  int _couponCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final member = await _memberService.getMemberDetail(widget.memberId);
      final coupons = await _couponService.getMemberCoupons(widget.memberId, status: 1);
      
      setState(() {
        _member = member;
        _couponCount = coupons.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('错误', '加载失败: $e', backgroundColor: AppColors.error);
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
        title: const Text('会员详情', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Get.snackbar('提示', '编辑功能开发中', backgroundColor: AppColors.info);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _member == null
              ? const Center(child: Text('会员不存在'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildMemberCard(),
                        _buildLevelProgress(),
                        _buildStatsSection(),
                        _buildActionSection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildMemberCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _member!.memberName ?? '会员',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _member!.memberLevel ?? '普通会员',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_member!.availablePoints ?? 0}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('可用积分', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(Icons.phone, _member!.phone ?? '-'),
              _buildInfoItem(Icons.calendar_today, _member!.registerDate?.substring(0, 10) ?? '-'),
              _buildInfoItem(_member!.gender == 'male' ? Icons.male : Icons.female, _member!.genderText),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _buildLevelProgress() {
    final levels = ['普通', '银卡', '金卡', '钻卡'];
    final currentIndex = levels.indexOf(_member!.memberLevel ?? '普通');
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
              const Text('会员等级', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              Text(_member!.memberLevel ?? '普通会员', style: const TextStyle(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(levels.length, (index) {
              final isActive = index <= currentIndex;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < levels.length - 1 ? 8 : 0),
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: levels.map((l) => Text(l, style: TextStyle(fontSize: 11, color: AppColors.textHint))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('消费统计', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '累计消费',
                  '¥${_member!.totalConsume?.toStringAsFixed(2) ?? '0.00'}',
                  Icons.account_balance_wallet,
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  '可用优惠券',
                  '$_couponCount 张',
                  Icons.local_offer,
                  AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '总积分',
                  '${_member!.totalPoints ?? 0}',
                  Icons.stars,
                  AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  '会员状态',
                  _member!.statusText,
                  Icons.verified,
                  AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                Text(label, style: TextStyle(fontSize: 11, color: AppColors.textHint)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildActionTile(
            '积分明细',
            Icons.history,
            () => Get.to(() => PointRecordPage(memberId: widget.memberId)),
          ),
          _buildActionTile(
            '优惠券',
            Icons.local_offer,
            () => Get.to(() => CouponListPage(memberId: widget.memberId)),
          ),
          _buildActionTile(
            '消费记录',
            Icons.receipt_long,
            () => Get.snackbar('提示', '消费记录功能开发中', backgroundColor: AppColors.info),
          ),
          _buildActionTile(
            '积分兑换',
            Icons.swap_horiz,
            () => _showRedeemDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
        onTap: onTap,
      ),
    );
  }

  void _showRedeemDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('积分兑换'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('可用积分: ${_member!.availablePoints ?? 0}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '兑换积分',
                hintText: '请输入要兑换的积分',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text('100积分 = 1元', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final points = int.tryParse(controller.text) ?? 0;
              if (points <= 0) {
                Get.snackbar('提示', '请输入有效的积分', backgroundColor: AppColors.warning);
                return;
              }
              if (points > (_member!.availablePoints ?? 0)) {
                Get.snackbar('提示', '积分不足', backgroundColor: AppColors.warning);
                return;
              }
              Navigator.pop(ctx);
              try {
                await _memberService.redeemPoints(memberId: widget.memberId, points: points);
                Get.snackbar('成功', '兑换成功', backgroundColor: AppColors.success);
                _loadData();
              } catch (e) {
                Get.snackbar('错误', '兑换失败: $e', backgroundColor: AppColors.error);
              }
            },
            child: const Text('确认兑换'),
          ),
        ],
      ),
    );
  }
}
