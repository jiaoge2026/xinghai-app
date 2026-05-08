import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/attendance_model.dart';
import '../../data/services/attendance_service.dart';
import '../providers/auth_provider.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final AttendanceService _service = AttendanceService();
  final ScrollController _scrollController = ScrollController();

  AttendanceModel? _todayAttendance;
  AttendanceStatModel? _monthlyStats;
  List<AttendanceModel> _historyList = [];
  bool _isLoading = true;
  bool _isClockingIn = false;
  bool _hasMore = true;
  int _page = 1;
  String _currentMonth = '';

  @override
  void initState() {
    super.initState();
    _currentMonth = _getCurrentMonth();
    _scrollController.addListener(_onScroll);
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getCurrentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadHistory();
      }
    }
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; });

    try {
      final results = await Future.wait([
        _service.getTodayAttendance(),
        _service.getMonthlyStats(_currentMonth),
        _service.getPage(startDate: '$_currentMonth-01', page: 1, pageSize: 20),
      ]);

      setState(() {
        _todayAttendance = results[0] as AttendanceModel?;
        _monthlyStats = results[1] as AttendanceStatModel;
        _historyList = results[2] as List<AttendanceModel>;
        _page = 1;
        _hasMore = (results[2] as List<AttendanceModel>).length >= 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败：$e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _loadHistory() async {
    if (_isLoading || !_hasMore) return;

    setState(() { _isLoading = true; });

    try {
      final list = await _service.getPage(
        startDate: '$_currentMonth-01',
        page: _page + 1,
        pageSize: 20,
      );

      setState(() {
        _historyList.addAll(list);
        _page++;
        _hasMore = list.length >= 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  Future<void> _clockIn() async {
    setState(() { _isClockingIn = true; });

    try {
      await _service.clockIn();
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('打卡成功'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打卡失败：$e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() { _isClockingIn = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('考勤打卡'),
        elevation: 0,
      ),
      body: _isLoading && _historyList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildClockInCard(),
                    const SizedBox(height: 16),
                    _buildTodayStatusCard(),
                    const SizedBox(height: 16),
                    _buildMonthlyStatsCard(),
                    const SizedBox(height: 16),
                    _buildHistoryTitle(),
                    const SizedBox(height: 8),
                    _buildHistoryList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildClockInCard() {
    final now = DateTime.now();
    final isWorkingHours = now.hour >= 8 && now.hour < 20;
    final canClockIn = isWorkingHours && (!_todayAttendance!.isCheckedIn || !_todayAttendance!.isCheckedOut);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${now.year}年${now.month}月${now.day}日 ${_getWeekday(now.weekday)}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (_isClockingIn || !canClockIn) ? null : _clockIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.white.withOpacity(0.5),
                disabledForegroundColor: Colors.white70,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                elevation: 0,
              ),
              child: _isClockingIn
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : Text(
                      _todayAttendance?.isCheckedIn == true
                          ? (_todayAttendance?.isCheckedOut == true ? '今日已打卡' : '下班打卡')
                          : '上班打卡',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '今日打卡状态',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatusItem(
                  '上班时间',
                  _todayAttendance?.checkInTime ?? '--:--',
                  Icons.login,
                  _todayAttendance?.isCheckedIn == true ? AppColors.success : AppColors.textHint,
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.divider),
              Expanded(
                child: _buildStatusItem(
                  '下班时间',
                  _todayAttendance?.checkOutTime ?? '--:--',
                  Icons.logout,
                  _todayAttendance?.isCheckedOut == true ? AppColors.success : AppColors.textHint,
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.divider),
              Expanded(
                child: _buildStatusItem(
                  '考勤状态',
                  _todayAttendance?.statusText ?? '未打卡',
                  Icons.check_circle_outline,
                  _getStatusColor(_todayAttendance?.status ?? ''),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'NORMAL':
        return AppColors.success;
      case 'LATE':
        return AppColors.warning;
      case 'ABSENT':
        return AppColors.error;
      case 'EARLY_LEAVE':
        return AppColors.warning;
      default:
        return AppColors.textHint;
    }
  }

  Widget _buildMonthlyStatsCard() {
    return Container(
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
              Text(
                '$_currentMonth 月考勤统计',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              Text(
                '共 ${_monthlyStats?.presentDays ?? 0} 天',
                style: const TextStyle(fontSize: 14, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem('出勤天数', '${_monthlyStats?.presentDays ?? 0}', AppColors.success),
              const SizedBox(width: 16),
              _buildStatItem('迟到次数', '${_monthlyStats?.lateDays ?? 0}', AppColors.warning),
              const SizedBox(width: 16),
              _buildStatItem('请假天数', '${_monthlyStats?.leaveDays ?? 0}', AppColors.info),
              const SizedBox(width: 16),
              _buildStatItem('工时', '${_monthlyStats?.totalWorkHours.toStringAsFixed(1) ?? '0'}', AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTitle() {
    return const Text(
      '历史考勤',
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    );
  }

  Widget _buildHistoryList() {
    if (_historyList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.history, size: 48, color: AppColors.textHint),
              const SizedBox(height: 8),
              const Text('暂无考勤记录', style: TextStyle(color: AppColors.textHint)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _historyList.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _historyList.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final item = _historyList[index];
        return _buildHistoryItem(item);
      },
    );
  }

  Widget _buildHistoryItem(AttendanceModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getStatusColor(item.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.workDate.split('-').last,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getStatusColor(item.status)),
                ),
                Text(
                  item.workDate.split('-')[1] + '月',
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.workDate,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '上班: ${item.checkInTime ?? '--:--'}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '下班: ${item.checkOutTime ?? '--:--'}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(item.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              item.statusText,
              style: TextStyle(fontSize: 12, color: _getStatusColor(item.status)),
            ),
          ),
        ],
      ),
    );
  }

  String _getWeekday(int weekday) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[weekday - 1];
  }
}
