import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/sales_service.dart';

class ProjectOrderListPage extends StatefulWidget {
  const ProjectOrderListPage({super.key});

  @override
  State<ProjectOrderListPage> createState() => _ProjectOrderListPageState();
}

class _ProjectOrderListPageState extends State<ProjectOrderListPage> {
  final SalesService _svc = SalesService();
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _svc.getProjectOrderList();
      setState(() { _list = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('工程项目订单'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('$_error', style: const TextStyle(color: Colors.red)))
              : _list.isEmpty
                  ? const Center(child: Text('暂无工程项目订单', style: TextStyle(color: Colors.grey)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        itemCount: _list.length,
                        itemBuilder: (ctx, i) {
                          final o = _list[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.withOpacity(0.1),
                              child: const Icon(Icons.business, color: Colors.blue),
                            ),
                            title: Text(o['orderNo'] ?? '订单 #${o['id']}'),
                            subtitle: Text('客户: ${o['customerName'] ?? '-'}  |  金额: ¥${o['totalAmount'] ?? 0}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Get.toNamed('/project_order_detail', arguments: o['id']),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_project_order',
        onPressed: () => Get.snackbar('提示', '工程项目订单创建开发中', backgroundColor: Colors.orange),
        child: const Icon(Icons.add),
      ),
    );
  }
}
