import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/coupon_model.dart';
import '../../data/services/coupon_service.dart';

class CouponListPage extends StatefulWidget {
  final int memberId;

  const CouponListPage({super.key, required this.memberId});

  @override
  State<CouponListPage> createState() => _CouponListPageState();
}

class _CouponListPageState extends State<CouponListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CouponService _couponService = CouponService();

  final List<String> _tabTitles = ['可用', '已使用', '已过期'];
  final List<int?> _tabStatuses = [1, 2, 3];

  Map<int?, List<CouponModel>> _couponsCache = {};
  Map<int?, bool> _loadingCache = {};
  Map<int?, bool> _hasMoreCache = {};
  Map<int?, int> _pageCache = {};
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabTitles.length, vsync: this);
    _tabController.addListener(_onTabChanged);

    for (int i = 0; i < _tabTitles.length; i++) {
      _loadingCache[_tabStatuses[i]] = false;
      _hasMoreCache[_tabStatuses[i]] = true;
      _pageCache[_tabStatuses[i]] = 1;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCoupons(refresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _currentTabIndex = _tabController.index;
    });

    final status = _tabStatuses[_currentTabIndex];
    if (_couponsCache[status] == null) {
      _loadCoupons(refresh: true);
    }
  }

  Future<void> _loadCoupons({bool refresh = false}) async {
    final status = _tabStatuses[_currentTabIndex];

    if (refresh) {
      _pageCache[status] = 1;
      _hasMoreCache[status] = true;
      _couponsCache[status] = [];
    }

    if (_loadingCache[status] == true || _hasMoreCache[status] != true) return;

    setState(() {
      _loadingCache[status] = true;
    });

    try {
      final page = _pageCache[status] ?? 1;
      final coupons = await _couponService.getMemberCoupons(
        widget.memberId,
        status: status,
        page: page,
      );

      setState(() {
        if (refresh) {
          _couponsCache[status] = coupons;
        } else {
          _couponsCache[status] = [
            ...(_couponsCache[status] ?? []),
            ...coupons,
          ];
        }

        if (coupons.length < 20) {
          _hasMoreCache[status] = false;
        }
        _pageCache[status] = page + 1;
        _loadingCache[status] = false;
      });
    } catch (e) {
      setState(() {
        _loadingCache[status] = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败：$e'), backgroundColor: AppColors.error),
      );
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
        title: const Text('我的优惠券', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: false,
          tabs: _tabTitles.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(_tabTitles.length, (index) {
          final status = _tabStatuses[index];
          return _buildCouponList(status);
        }),
      ),
    );
  }

  Widget _buildCouponList(int? status) {
    final coupons = _couponsCache[status] ?? [];
    final isLoading = _loadingCache[status] ?? false;

    if (isLoading && coupons.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (coupons.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _loadCoupons(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: coupons.length,
        itemBuilder: (context, index) {
          return _buildCouponCard(coupons[index]);
        },
      ),
    );
  }

  Widget _buildCouponCard(CouponModel coupon) {
    final isAvailable = coupon.isAvailable;
    final isExpired = coupon.isExpired;

    Color bgColor;
    Color textColor;
    if (!isAvailable && !isExpired) {
      bgColor = AppColors.textHint.withOpacity(0.3);
      textColor = AppColors.textHint;
    } else if (isExpired) {
      bgColor = AppColors.textHint.withOpacity(0.3);
      textColor = AppColors.textHint;
    } else {
      bgColor = AppColors.error;
      textColor = Colors.white;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isAvailable ? AppColors.error.withOpacity(0.3) : AppColors.divider,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 100,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isAvailable ? AppColors.error.withOpacity(0.1) : AppColors.background,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (coupon.discountAmount != null && coupon.discountAmount! > 0)
                        Text(
                          '¥${coupon.discountAmount!.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isAvailable ? AppColors.error : AppColors.textHint,
                          ),
                        )
                      else
                        Text(
                          '${(coupon.discountAmount ?? 0) * 10}%',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isAvailable ? AppColors.error : AppColors.textHint,
                          ),
                        ),
                      Text(
                        coupon.couponTypeText,
                        style: TextStyle(
                          fontSize: 12,
                          color: isAvailable ? AppColors.error : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coupon.couponName ?? '优惠券',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: isAvailable ? AppColors.textPrimary : AppColors.textHint,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (coupon.minConsume != null && coupon.minConsume! > 0)
                          Text(
                            '满${coupon.minConsume!.toStringAsFixed(0)}可用',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          '${coupon.validFrom?.substring(0, 10) ?? ''} 至 ${coupon.validTo?.substring(0, 10) ?? ''}',
                          style: TextStyle(color: AppColors.textHint, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 60,
                  alignment: Alignment.center,
                  child: isAvailable
                      ? Icon(Icons.check_circle, color: AppColors.success, size: 32)
                      : Text(
                          isExpired ? '已过期' : '已使用',
                          style: TextStyle(color: AppColors.textHint, fontSize: 12),
                        ),
                ),
              ],
            ),
          ),
          if (isAvailable)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('可用', style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, size: 80, color: AppColors.textHint.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            '暂无优惠券',
            style: TextStyle(color: AppColors.textHint, fontSize: 16),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Get.snackbar('提示', '领券功能开发中', backgroundColor: AppColors.info);
            },
            icon: const Icon(Icons.add),
            label: const Text('去领券'),
          ),
        ],
      ),
    );
  }
}
