import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/services/dashboard_service.dart';

class EngineerRankingPage extends StatefulWidget {
  const EngineerRankingPage({super.key});

  @override
  State<EngineerRankingPage> createState() => _EngineerRankingPageState();
}

class _EngineerRankingPageState extends State<EngineerRankingPage> {
  final DashboardService _dashboardService = DashboardService();
  
  List<EngineerRankingModel> _ranking = [];
  bool _isLoading = true;
  String _selectedMonth = DateTime.now().toString().substring(0, 7);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final ranking = await _dashboardService.getEngineerRanking(month: _selectedMonth);
      setState(() {
        _ranking = ranking;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败：$e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _selectMonth() async {
    final parts = _selectedMonth.split('-');
    final initialDate = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
      });
      _loadData();
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
        title: const Text('工程师绩效排行', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          TextButton.icon(
            onPressed: _selectMonth,
            icon: const Icon(Icons.calendar_month, color: Colors.white, size: 20),
            label: Text(_selectedMonth, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ranking.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 80, color: AppColors.textHint.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text('暂无排行数据', style: TextStyle(color: AppColors.textHint)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _ranking.length,
                    itemBuilder: (context, index) {
                      return _buildRankingItem(_ranking[index], index + 1);
                    },
                  ),
                ),
    );
  }

  Widget _buildRankingItem(EngineerRankingModel engineer, int rank) {
    Color? bgColor;
    Color? rankColor;
    
    if (rank == 1) {
      bgColor = const Color(0xFFFFD700).withOpacity(0.1);
      rankColor = const Color(0xFFFFD700);
    } else if (rank == 2) {
      bgColor = const Color(0xFFC0C0C0).withOpacity(0.1);
      rankColor = const Color(0xFFC0C0C0);
    } else if (rank == 3) {
      bgColor = const Color(0xFFCD7F32).withOpacity(0.1);
      rankColor = const Color(0xFFCD7F32);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: rankColor?.withOpacity(0.2) ?? AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: rank <= 3
                  ? Icon(Icons.emoji_events, color: rankColor, size: 20)
                  : Text(
                      '$rank',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: rankColor ?? AppColors.primary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: engineer.avatar != null && engineer.avatar!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(engineer.avatar!, fit: BoxFit.cover),
                  )
                : const Icon(Icons.person, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  engineer.engineerName ?? '工程师',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildStatChip('完成', '${engineer.completedCount}单', AppColors.info),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      '好评率',
                      '${((engineer.goodRate ?? 0) * 100).toStringAsFixed(0)}%',
                      AppColors.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (engineer.avgScore != null)
                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.warning, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      engineer.avgScore!.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 4),
              Text(
                '第 $rank 名',
                style: TextStyle(
                  color: rankColor ?? AppColors.textHint,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: color, fontSize: 11),
      ),
    );
  }
}
