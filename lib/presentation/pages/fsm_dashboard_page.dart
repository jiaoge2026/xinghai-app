import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/services/dashboard_service.dart';
import 'engineer_ranking_page.dart';

class FsmDashboardPage extends StatefulWidget {
  const FsmDashboardPage({super.key});

  @override
  State<FsmDashboardPage> createState() => _FsmDashboardPageState();
}

class _FsmDashboardPageState extends State<FsmDashboardPage> {
  final DashboardService _dashboardService = DashboardService();
  
  FsmDashboardModel? _fsmData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final data = await _dashboardService.getFsmDashboard();
      setState(() {
        _fsmData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
        title: const Text('FSM驾驶舱', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusDistribution(),
                    const SizedBox(height: 16),
                    _buildEngineerRanking(),
                    const SizedBox(height: 16),
                    _buildTypeStats(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusDistribution() {
    final pending = _fsmData?.pendingCount ?? 0;
    final assigned = _fsmData?.assignedCount ?? 0;
    final inProgress = _fsmData?.inProgressCount ?? 0;
    final completed = _fsmData?.completedCount ?? 0;
    final cancelled = _fsmData?.cancelledCount ?? 0;
    final total = pending + assigned + inProgress + completed + cancelled;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('工单状态分布', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 16),
          if (total > 0) _buildPieChart(total, pending, assigned, inProgress, completed, cancelled),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem('待派单', pending, AppColors.statusPending),
              _buildLegendItem('已派单', assigned, AppColors.statusAssigned),
              _buildLegendItem('进行中', inProgress, AppColors.statusInProgress),
              _buildLegendItem('已完成', completed, AppColors.statusCompleted),
              _buildLegendItem('已取消', cancelled, AppColors.statusCancelled),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(int total, int pending, int assigned, int inProgress, int completed, int cancelled) {
    return SizedBox(
      height: 160,
      child: Row(
        children: [
          Expanded(
            child: CustomPaint(
              size: const Size(140, 140),
              painter: PieChartPainter(
                pending: pending,
                assigned: assigned,
                inProgress: inProgress,
                completed: completed,
                cancelled: cancelled,
                total: total,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('总工单', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text('$total', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text('$label: $count', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }

  Widget _buildEngineerRanking() {
    final ranking = _fsmData?.engineerRanking ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('工程师接单排行', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              TextButton(
                onPressed: () => Get.to(() => const EngineerRankingPage()),
                child: const Text('查看全部'),
              ),
            ],
          ),
          if (ranking.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('暂无数据', style: TextStyle(color: AppColors.textHint))),
            )
          else
            ...ranking.take(5).map((e) => _buildEngineerItem(e)),
        ],
      ),
    );
  }

  Widget _buildEngineerItem(EngineerWorkOrderStatModel engineer) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '${engineer.completedCount}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(engineer.engineerName ?? '工程师', style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  '完成${engineer.completedCount}单 | 好评率${((engineer.goodRate ?? 0) * 100).toStringAsFixed(0)}%',
                  style: TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeStats() {
    final typeStats = _fsmData?.typeStats ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('工单类型统计', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 16),
          if (typeStats.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('暂无数据', style: TextStyle(color: AppColors.textHint))),
            )
          else
            ...typeStats.map((e) => _buildTypeBar(e)),
        ],
      ),
    );
  }

  Widget _buildTypeBar(WorkOrderTypeStatModel stat) {
    final maxCount = typeStats.isNotEmpty ? typeStats.map((e) => e.count).reduce((a, b) => a > b ? a : b) : 1;
    final ratio = stat.count / maxCount;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(stat.typeName ?? '未知', style: const TextStyle(fontSize: 13)),
              Text('${stat.count}单', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ratio,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<WorkOrderTypeStatModel> get typeStats => _fsmData?.typeStats ?? [];
}

class PieChartPainter extends CustomPainter {
  final int pending, assigned, inProgress, completed, cancelled, total;

  PieChartPainter({
    required this.pending,
    required this.assigned,
    required this.inProgress,
    required this.completed,
    required this.cancelled,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    double startAngle = -3.14159 / 2;
    final colors = [AppColors.statusPending, AppColors.statusAssigned, AppColors.statusInProgress, AppColors.statusCompleted, AppColors.statusCancelled];
    final counts = [pending, assigned, inProgress, completed, cancelled];

    for (int i = 0; i < counts.length; i++) {
      if (counts[i] == 0) continue;
      final sweepAngle = (counts[i] / total) * 2 * 3.14159;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
