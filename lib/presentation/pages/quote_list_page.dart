import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/sales_service.dart';
import 'quote_form_page.dart';

class QuoteListPage extends StatefulWidget {
  const QuoteListPage({super.key});

  @override
  State<QuoteListPage> createState() => _QuoteListPageState();
}

class _QuoteListPageState extends State<QuoteListPage> {
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
      final data = await _svc.getQuoteList();
      setState(() { _list = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('报价单'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('$_error', style: const TextStyle(color: Colors.red)))
              : _list.isEmpty
                  ? const Center(child: Text('暂无报价单', style: TextStyle(color: Colors.grey)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        itemCount: _list.length,
                        itemBuilder: (ctx, i) {
                          final q = _list[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange.withOpacity(0.1),
                              child: const Icon(Icons.receipt_long, color: Colors.orange),
                            ),
                            title: Text('报价单 #${q['quoteNo'] ?? q['id']}'),
                            subtitle: Text('客户: ${q['customerName'] ?? '-'}  |  金额: ¥${q['totalAmount'] ?? 0}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await Get.to(() => QuoteFormPage(quote: q));
                              _load();
                            },
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_quote',
        onPressed: () async {
          await Get.to(() => const QuoteFormPage());
          _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
