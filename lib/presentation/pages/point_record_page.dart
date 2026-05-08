import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/member_model.dart';
import '../../data/services/member_service.dart';

class PointRecordPage extends StatefulWidget {
  final int memberId;

  const PointRecordPage({super.key, required this.memberId});

  @override
  State<PointRecordPage> createState() => _PointRecordPageState();
}

class _PointRecordPageState extends State<PointRecordPage> {
  final MemberService _memberService = MemberService();
  final ScrollController _scrollController = ScrollController();

  List<PointRecordModel> _records = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  int _balance = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecords(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadRecords();
      }
    }
  }

  Future<void> _loadRecords({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _page = 1;
        _hasMore = true;
        _records = [];
      }
    });

    try {
      final records = await _memberService.getPointRecords(
        widget.memberId,
        page: _page,
      );

      setState(() {
        if (refresh) {
          _records = records;
        } else {
          _records.addAll(records);
        }
        _hasMore = records.length >= 20;
        _page++;
        _isLoading = false;
        if (_records.isNotEmpty) {
          _balance = _records.first.memberId == widget.memberId 
              ? (_records.first.points > 0 ? _calculateBalance() : 0) 
              : 0;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败：$e'), backgroundColor: AppColors.error),
      );
    }
  }

  int _calculateBalance() {
    int balance = 0;
    for (final record in _records) {
      if (record.type == 1) {
        balance += record.points;
      } else if (record.type == 2) {
        balance -= record.points;
      }
    }
    return balance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('积分明细', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.primary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    const Text('当前积分', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      '$_balance',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildRecordList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordList() {
    if (_isLoading && _records.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: AppColors.textHint.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('暂无积分记录', style: TextStyle(color: AppColors.textHint, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadRecords(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _records.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _records.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildRecordItem(_records[index]);
        },
      ),
    );
  }

  Widget _buildRecordItem(PointRecordModel record) {
    final isGain = record.type == 1;
    final color = isGain ? AppColors.success : AppColors.error;
    final icon = isGain ? Icons.add_circle : Icons.remove_circle;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.typeText,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  record.source ?? record.remark ?? '',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                if (record.orderNo != null)
                  Text(
                    '订单: ${record.orderNo}',
                    style: TextStyle(color: AppColors.textHint, fontSize: 12),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isGain ? '+' : '-'}${record.points}',
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                record.createdAt?.toString().substring(0, 16) ?? '',
                style: TextStyle(color: AppColors.textHint, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
