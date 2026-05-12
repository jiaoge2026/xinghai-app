import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/sales_service.dart';

class QuoteFormPage extends StatefulWidget {
  final Map<String, dynamic>? quote;
  const QuoteFormPage({super.key, this.quote});

  @override
  State<QuoteFormPage> createState() => _QuoteFormPageState();
}

class _QuoteFormPageState extends State<QuoteFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _svc = SalesService();
  final _noCtrl = TextEditingController();
  final _customerNameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController();
  bool _saving = false;

  bool get isEdit => widget.quote != null;

  @override
  void initState() {
    super.initState();
    if (widget.quote != null) {
      _noCtrl.text = widget.quote!['quoteNo'] ?? '';
      _customerNameCtrl.text = widget.quote!['customerName'] ?? '';
      _amountCtrl.text = (widget.quote!['totalAmount'] ?? 0).toString();
      _remarkCtrl.text = widget.quote!['remark'] ?? '';
    }
  }

  @override
  void dispose() {
    _noCtrl.dispose();
    _customerNameCtrl.dispose();
    _amountCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final body = {
        'quoteNo': _noCtrl.text.trim(),
        'customerName': _customerNameCtrl.text.trim(),
        'totalAmount': double.tryParse(_amountCtrl.text.trim()) ?? 0,
        'remark': _remarkCtrl.text.trim(),
      };
      if (isEdit) {
        await _svc.updateCustomer(widget.quote!['id'], body);
      } else {
        await _svc.createQuote(body);
      }
      Get.back();
      Get.snackbar('成功', isEdit ? '报价单已更新' : '报价单已创建',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('失败', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? '编辑报价单' : '新建报价单')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _noCtrl,
              decoration: const InputDecoration(labelText: '报价单号 *', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? '请输入报价单号' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _customerNameCtrl,
              decoration: const InputDecoration(labelText: '客户名称 *', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? '请输入客户名称' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountCtrl,
              decoration: const InputDecoration(labelText: '总金额', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _remarkCtrl,
              decoration: const InputDecoration(labelText: '备注', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isEdit ? '保存修改' : '创建报价单'),
            ),
          ],
        ),
      ),
    );
  }
}
