import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/opportunity_model.dart';
import '../../data/services/crm_service.dart';
import '../providers/auth_provider.dart';
import 'opportunity_detail_page.dart';
import 'opportunity_form_page.dart';

class OpportunityListPage extends StatefulWidget {
  const OpportunityListPage({super.key});

  @override
  State<OpportunityListPage> createState() => _OpportunityListPageState();
}

class _OpportunityListPageState extends State<OpportunityListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final CRMService _crmService = CRMService();

  final List<String> _tabTitles = ['全部', '新商机', '已Qualified', '提案', '谈判', '成交', '输单'];
  final List<int?> _tabStages = [null, 1, 2, 3, 4, 5, 6];

  Map<int?, List<OpportunityModel>> _opportunitiesCache = {};
  Map<int?, bool> _loadingCache = {};
  Map<int?, bool> _hasMoreCache = {};
  Map<int?, int> _pageCache = {};
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabTitles.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);

    for (int i = 0; i < _tabTitles.length; i++) {
      _loadingCache[_tabStages[i]] = false;
      _hasMoreCache[_tabStages[i]] = true;
      _pageCache[_tabStages[i]] = 1;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData(refresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _currentTabIndex = _tabController.index;
    });

    final stage = _tabStages[_currentTabIndex];
    if (_opportunitiesCache[stage] == null) {
      _loadData(refresh: true);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final stage = _tabStages[_currentTabIndex];
      if (_loadingCache[stage] != true && _hasMoreCache[stage] == true) {
        _loadData();
      }
    }
  }

  Future<void> _loadData({bool refresh = false}) async {
    final stage = _tabStages[_currentTabIndex];

    if (refresh) {
      _pageCache[stage] = 1;
      _hasMoreCache[stage] = true;
      _opportunitiesCache[stage] = [];
    }

    if (_loadingCache[stage] == true || _hasMoreCache[stage] != true) return;

    setState(() {
      _loadingCache[stage] = true;
    });

    try {
      final page = _pageCache[stage] ?? 1;
      final authProvider = context.read<AuthProvider>();
      final employeeId = authProvider.currentUser?.id;

      final list = await _crmService.getOpportunities(
        stage: stage,
        employeeId: employeeId,
        page: page,
      );

      setState(() {
        if (refresh) {
          _opportunitiesCache[stage] = list;
        } else {
          _opportunitiesCache[stage] = [
            ...(_opportunitiesCache[stage] ?? []),
            ...list,
          ];
        }

        if (list.length < 20) {
          _hasMoreCache[stage] = false;
        }
        _pageCache[stage] = page + 1;
        _loadingCache[stage] = false;
      });
    } catch (e) {
      setState(() {
        _loadingCache[stage] = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载失败：$e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadData(refresh: true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '商机列表',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: _showFunnelStats,
            tooltip: '商机漏斗',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: false,
          tabs: _tabTitles.map((title) => Tab(text: title)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(_tabTitles.length, (index) {
          final stage = _tabStages[index];
          return _buildOpportunityList(stage);
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const OpportunityFormPage()),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildOpportunityList(int? stage) {
    final opportunities = _opportunitiesCache[stage] ?? [];
    final isLoading = _loadingCache[stage] ?? false;
    final hasMore = _hasMoreCache[stage] ?? true;

    if (isLoading && opportunities.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (opportunities.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: opportunities.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= opportunities.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final opportunity = opportunities[index];
          return _buildOpportunityCard(opportunity);
        },
      ),
    );
  }

  Widget _buildOpportunityCard(OpportunityModel opportunity) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => Get.toNamed('/opportunity_detail', arguments: opportunity.id),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      opportunity.opportunityName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStageColor(opportunity.stage).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      opportunity.stageText,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStageColor(opportunity.stage),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.business, size: 16, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    opportunity.customerName,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.attach_money, size: 16, color: AppColors.success),
                        Text(
                          '¥${opportunity.estimatedAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${opportunity.probability}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    opportunity.employeeName,
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                  ),
                ],
              ),
              if (opportunity.expectedCloseDate != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.event, size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      '预计关闭: ${opportunity.expectedCloseDate}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                    ),
                  ],
                ),
              ],
            ],
          ),
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
            Icons.trending_up,
            size: 80,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无商机',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击右下角按钮新增商机',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFunnelStats() async {
    try {
      final stats = await _crmService.getFunnelStats();
      if (!mounted) return;

      showModalBottomSheet(
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
                '商机漏斗统计',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(_tabStages.length - 1, (index) {
                final stage = _tabStages[index + 1]!;
                final count = stats[OpportunityModel.getStageName(stage)] ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getStageColor(stage),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          OpportunityModel.getStageName(stage),
                          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                        ),
                      ),
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _getStageColor(stage),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取漏斗统计失败：$e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}
