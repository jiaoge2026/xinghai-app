import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/sales_service.dart';
import 'customer_form_page.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
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
      final data = await _svc.getCustomerList();
      setState(() { _list = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('工程项目客户'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('$_error', style: const TextStyle(color: Colors.red)))
              : _list.isEmpty
                  ? const Center(child: Text('暂无客户', style: TextStyle(color: Colors.grey)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        itemCount: _list.length,
                        itemBuilder: (ctx, i) {
                          final c = _list[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: Text(c['customerName']?.substring(0, 1) ?? '?',
                                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(c['customerName'] ?? ''),
                            subtitle: Text('${c['industry'] ?? ''}  |  ${c['contactName'] ?? ''}  |  ${c['contactPhone'] ?? ''}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await Get.to(() => CustomerFormPage(customer: c));
                              _load();
                            },
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_customer',
        onPressed: () async {
          await Get.to(() => const CustomerFormPage());
          _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
