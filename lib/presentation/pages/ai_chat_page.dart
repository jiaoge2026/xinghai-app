import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/ai_message_model.dart';
import '../../data/models/ai_role_model.dart';
import '../../data/services/ai_chat_service.dart';

class AIChatPage extends StatefulWidget {
  final String? sessionId;
  final AIRoleModel? role;

  const AIChatPage({super.key, this.sessionId, this.role});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final AIChatService _chatService = AIChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<AIMessageModel> _messages = [];
  List<AIRoleModel> _roles = [];
  AIRoleModel? _currentRole;
  String? _currentSessionId;
  bool _isLoading = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _currentSessionId = widget.sessionId;
    _currentRole = widget.role;
    _loadRoles();
    if (_currentSessionId != null && _currentRole != null) {
      _loadMessages();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRoles() async {
    try {
      final roles = await _chatService.getRoles();
      setState(() {
        _roles = roles;
        if (_currentRole == null && roles.isNotEmpty) {
          _currentRole = roles.first;
        }
      });
    } catch (e) {
      _roles = [
        AIRoleModel(
          roleCode: 'fsm',
          roleName: 'FSM助手',
          roleDescription: '工单与服务管理助手',
          welcomeMessage: '您好！我是FSM助手，可以帮您处理工单、服务相关问题。',
          suggestedQuestions: ['如何创建工单？', '查看今日工单', '工单状态说明'],
        ),
        AIRoleModel(
          roleCode: 'finance',
          roleName: '财务助手',
          roleDescription: '财务与账务管理助手',
          welcomeMessage: '您好！我是财务助手，可以帮您处理财务、报销相关问题。',
          suggestedQuestions: ['如何申请报销？', '查看薪资明细', '本月支出统计'],
        ),
        AIRoleModel(
          roleCode: 'inventory',
          roleName: '库存助手',
          roleDescription: '库存与采购管理助手',
          welcomeMessage: '您好！我是库存助手，可以帮您处理库存、采购相关问题。',
          suggestedQuestions: ['当前库存查询', '如何申请采购？', '库存预警说明'],
        ),
      ];
      setState(() {
        if (_currentRole == null && _roles.isNotEmpty) {
          _currentRole = _roles.first;
        }
      });
    }
  }

  Future<void> _loadMessages() async {
    if (_currentSessionId == null) return;
    setState(() => _isLoading = true);
    try {
      final messages = await _chatService.getSessionMessages(_currentSessionId!);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载消息失败：$e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final query = _messageController.text.trim();
    if (query.isEmpty) return;
    if (_currentRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择AI角色'), backgroundColor: AppColors.warning),
      );
      return;
    }

    _messageController.clear();

    if (_currentSessionId == null) {
      try {
        _currentSessionId = await _chatService.createSession(_currentRole!.roleCode);
      } catch (e) {
        _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      }
    }

    final userMessage = AIMessageModel(
      id: DateTime.now().millisecondsSinceEpoch,
      sessionId: _currentSessionId!,
      query: query,
      response: '',
      roleCode: _currentRole!.roleCode,
      isMe: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final result = await _chatService.sendMessage(
        sessionId: _currentSessionId!,
        roleCode: _currentRole!.roleCode,
        query: query,
      );

      final aiMessage = AIMessageModel(
        id: DateTime.now().millisecondsSinceEpoch + 1,
        sessionId: _currentSessionId!,
        query: query,
        response: result['response'] ?? result['content'] ?? '抱歉，我现在无法回答这个问题。',
        roleCode: _currentRole!.roleCode,
        isMe: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiMessage);
        _isTyping = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isTyping = false);
      final errorMessage = AIMessageModel(
        id: DateTime.now().millisecondsSinceEpoch + 1,
        sessionId: _currentSessionId ?? '',
        query: '',
        response: '发送失败：$e',
        roleCode: _currentRole?.roleCode ?? '',
        isMe: false,
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(errorMessage);
      });
    }
  }

  Future<void> _clearSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空会话'),
        content: const Text('确定要清空当前会话吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true && _currentSessionId != null) {
      try {
        await _chatService.clearSession(_currentSessionId!);
        setState(() => _messages.clear());
      } catch (e) {
        setState(() => _messages.clear());
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
              '选择AI助手',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ..._roles.map((role) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _currentRole?.roleCode == role.roleCode
                        ? AppColors.primary
                        : AppColors.primaryLight,
                    child: Icon(
                      _getRoleIcon(role.roleCode),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(role.roleName),
                  subtitle: Text(role.roleDescription),
                  selected: _currentRole?.roleCode == role.roleCode,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _currentRole = role;
                      _currentSessionId = null;
                      _messages.clear();
                    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: GestureDetector(
          onTap: _showRoleSelector,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getRoleIcon(_currentRole?.roleCode ?? ''), size: 20),
              const SizedBox(width: 8),
              Text(_currentRole?.roleName ?? 'AI助手'),
              const Icon(Icons.arrow_drop_down, color: Colors.white),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearSession,
            tooltip: '清空会话',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessageList(),
          ),
          if (_messages.isEmpty && _currentRole != null) _buildSuggestedQuestions(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.smart_toy,
            size: 80,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _currentRole?.welcomeMessage ?? '您好！我是您的AI助手',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '请选择下方快捷问题开始对话',
            style: TextStyle(
              color: AppColors.textHint.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _messages.length) {
          return _buildTypingIndicator();
        }
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(AIMessageModel message) {
    final isMe = message.isMe;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isMe && message.query.isNotEmpty)
                    Text(
                      message.query,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  if (!isMe && message.response.isNotEmpty)
                    Text(
                      message.response,
                      style: TextStyle(
                        color: isMe ? Colors.white : AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : AppColors.textHint,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryDark,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(),
                const SizedBox(width: 4),
                _buildDot(),
                const SizedBox(width: 4),
                _buildDot(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.textHint.withOpacity(0.3 + value * 0.3),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () {
        setState(() {});
      },
    );
  }

  Widget _buildSuggestedQuestions() {
    final questions = _currentRole?.suggestedQuestions ?? [];
    if (questions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '快捷问题',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: questions.take(4).map((q) {
              return InkWell(
                onTap: () {
                  _messageController.text = q;
                  _sendMessage();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Text(
                    q,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: '输入您的问题...',
                hintStyle: const TextStyle(color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
