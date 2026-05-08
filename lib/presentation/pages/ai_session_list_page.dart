import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/ai_message_model.dart';
import '../../data/models/ai_role_model.dart';
import '../../data/services/ai_chat_service.dart';
import 'ai_chat_page.dart';

class AISessionListPage extends StatefulWidget {
  const AISessionListPage({super.key});

  @override
  State<AISessionListPage> createState() => _AISessionListPageState();
}

class _AISessionListPageState extends State<AISessionListPage> {
  final AIChatService _chatService = AIChatService();
  List<AISessionModel> _sessions = [];
  List<AIRoleModel> _roles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final sessions = await _chatService.getSessions();
      final roles = await _chatService.getRoles();
      setState(() {
        _sessions = sessions;
        _roles = roles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _sessions = [];
      _roles = [
        AIRoleModel(
          roleCode: 'fsm',
          roleName: 'FSM助手',
          roleDescription: '工单与服务管理助手',
          welcomeMessage: '您好！我是FSM助手',
          suggestedQuestions: ['如何创建工单？', '查看今日工单'],
        ),
        AIRoleModel(
          roleCode: 'finance',
          roleName: '财务助手',
          roleDescription: '财务与账务管理助手',
          welcomeMessage: '您好！我是财务助手',
          suggestedQuestions: ['如何申请报销？', '查看薪资明细'],
        ),
        AIRoleModel(
          roleCode: 'inventory',
          roleName: '库存助手',
          roleDescription: '库存与采购管理助手',
          welcomeMessage: '您好！我是库存助手',
          suggestedQuestions: ['当前库存查询', '如何申请采购？'],
        ),
      ];
    }
  }

  Future<void> _deleteSession(AISessionModel session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除会话'),
        content: const Text('确定要删除该会话吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _chatService.deleteSession(session.sessionId);
        setState(() {
          _sessions.removeWhere((s) => s.sessionId == session.sessionId);
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败：$e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  void _startNewSession(AIRoleModel role) {
    Get.to(() => AIChatPage(role: role));
  }

  void _showRoleSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选择AI助手类型',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ..._roles.map((role) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(
                      _getRoleIcon(role.roleCode),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(role.roleName),
                  subtitle: Text(role.roleDescription),
                  onTap: () {
                    Navigator.pop(context);
                    _startNewSession(role);
                  },
                )),
          ],
        ),
      ),
    );
  }

  IconData _getRoleIcon(String roleCode) {
    switch (roleCode) {
      case 'fsm':
        return Icons.engineering;
      case 'finance':
        return Icons.account_balance;
      case 'inventory':
        return Icons.inventory;
      default:
        return Icons.smart_toy;
    }
  }

  String _getRoleName(String roleCode) {
    final role = _roles.firstWhereOrNull((r) => r.roleCode == roleCode);
    return role?.roleName ?? 'AI助手';
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
          'AI助手',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? _buildEmptyState()
              : _buildSessionList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showRoleSelector,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无会话记录',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮开始新对话',
            style: TextStyle(
              color: AppColors.textHint.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sessions.length,
        itemBuilder: (context, index) {
          final session = _sessions[index];
          return _buildSessionCard(session);
        },
      ),
    );
  }

  Widget _buildSessionCard(AISessionModel session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          final role = _roles.firstWhereOrNull((r) => r.roleCode == session.roleCode);
          Get.to(() => AIChatPage(
                sessionId: session.sessionId,
                role: role,
              ));
        },
        onLongPress: () => _deleteSession(session),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Icon(
                  _getRoleIcon(session.roleCode),
                  color: AppColors.primary,
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
                          _getRoleName(session.roleCode),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          _formatTime(session.lastMessageTime),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.lastMessage ?? '开始新对话',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.textHint),
                onPressed: () => _deleteSession(session),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${time.month}/${time.day}';
    }
  }
}
