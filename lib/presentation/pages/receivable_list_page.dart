import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/sales_service.dart';

class ReceivableListPage extends StatefulWidget {
  const ReceivableListPage({super.key});

  @override
  State<ReceivableListPage> createState() => _ReceivableListPageState();
}

class _ReceivableListPageState extends State<ReceivableListPage> {
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
      final data = await _svc.getReceivableList();
      setState(() { _list = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  double get _total => _list.fold(0, (sum, r) => sum + (r['amount'] as num? ?? 0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('销售应收款'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.blue.withOpacity(0.05),
            child: Column(
              children: [
                const Text('应收总额', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Text('¥${_total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('$_error', style: const TextStyle(color: Colors.red)))
                    : _list.isEmpty
                        ? const Center(child: Text('暂无应收款', style: TextStyle(color: Colors.grey)))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              itemCount: _list.length,
                              itemBuilder: (ctx, i) {
                                final r = _list[i];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.red.withOpacity(0.1),
                                    child: const Icon(Icons.account_balance_wallet, color: Colors.red),
                                  ),
                                  title: Text('客户: ${r['customerName'] ?? '-'}'),
                                  subtitle: Text('订单: ${r['orderNo'] ?? '-'}'),
                                  trailing: Text('¥${(r['amount'] as num? ?? 0).toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
