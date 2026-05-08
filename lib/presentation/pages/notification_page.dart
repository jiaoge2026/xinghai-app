import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class NotificationModel {
  final int id;
  final String title;
  final String content;
  final String time;
  final bool isRead;
  final int type;

  NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.time,
    required this.isRead,
    required this.type,
  });
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<NotificationModel> _allNotifications = [
    NotificationModel(
      id: 1,
      title: '新工单分配',
      content: '工单 WO-20260507-0001 已分配给您，请及时处理。',
      time: '10:30',
      isRead: false,
      type: 1,
    ),
    NotificationModel(
      id: 2,
      title: '工单催单提醒',
      content: '工单 WO-20260506-0008 客户催促，请尽快处理。',
      time: '09:15',
      isRead: false,
      type: 2,
    ),
    NotificationModel(
      id: 3,
      title: '工单已完工',
      content: '工单 WO-20260506-0005 已完工，等待审核。',
      time: '昨天 18:00',
      isRead: true,
      type: 3,
    ),
    NotificationModel(
      id: 4,
      title: '系统通知',
      content: '您的账号已于 2026-05-07 08:00 登录。',
      time: '昨天 08:00',
      isRead: true,
      type: 0,
    ),
    NotificationModel(
      id: 5,
      title: '配件库存不足',
      content: '配件 "压缩机LG-123" 库存不足，请及时补充。',
      time: '05-06 14:00',
      isRead: true,
      type: 4,
    ),
  ];

  List<NotificationModel> _getFilteredNotifications(int type) {
    if (type == -1) return _allNotifications;
    return _allNotifications.where((n) => n.type == type).toList();
  }

  int _getUnreadCount() {
    return _allNotifications.where((n) => !n.isRead).length;
  }

  void _markAllAsRead() {
    setState(() {
      for (var n in _allNotifications) {
        n.isRead = true;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('消息通知'),
        elevation: 0,
        actions: [
          if (_getUnreadCount() > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('全部已读', style: TextStyle(color: Colors.white, fontSize: 14)),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: '全部 ${_allNotifications.length}'),
            Tab(text: '工单 ${_allNotifications.where((n) => n.type == 1 || n.type == 2 || n.type == 3).length}'),
            Tab(text: '系统 ${_allNotifications.where((n) => n.type == 0 || n.type == 4).length}'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationList(_getFilteredNotifications(-1)),
          _buildNotificationList(_getFilteredNotifications(1)),
          _buildNotificationList(_getFilteredNotifications(0)),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationModel> notifications) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text('暂无消息', style: TextStyle(color: AppColors.textHint, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: notification.isRead ? 0 : 1,
      color: notification.isRead ? Colors.white : AppColors.primary.withOpacity(0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () {
          setState(() {
            notification.isRead = true;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getTypeColor(notification.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _getTypeIcon(notification.type),
                  color: _getTypeColor(notification.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.content,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.time,
                      style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(int type) {
    switch (type) {
      case 1: return AppColors.primary;     // 工单分配
      case 2: return AppColors.warning;      // 催单
      case 3: return AppColors.success;      // 完工
      case 4: return AppColors.error;       // 库存
      default: return AppColors.textHint;   // 系统
    }
  }

  IconData _getTypeIcon(int type) {
    switch (type) {
      case 1: return Icons.assignment_ind;
      case 2: return Icons.alarm;
      case 3: return Icons.check_circle;
      case 4: return Icons.inventory;
      default: return Icons.notifications;
    }
  }
}
