import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/sales_service.dart';

class CustomerFormPage extends StatefulWidget {
  final Map<String, dynamic>? customer;
  const CustomerFormPage({super.key, this.customer});

  @override
  State<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends State<CustomerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _svc = SalesService();
  final _nameCtrl = TextEditingController();
  final _industryCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _saving = false;

  bool get isEdit => widget.customer != null;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _nameCtrl.text = widget.customer!['customerName'] ?? '';
      _industryCtrl.text = widget.customer!['industry'] ?? '';
      _contactCtrl.text = widget.customer!['contactName'] ?? '';
      _phoneCtrl.text = widget.customer!['contactPhone'] ?? '';
      _addressCtrl.text = widget.customer!['address'] ?? '';
      _descCtrl.text = widget.customer!['description'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _industryCtrl.dispose();
    _contactCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final body = {
        'customerName': _nameCtrl.text.trim(),
        'industry': _industryCtrl.text.trim(),
        'contactName': _contactCtrl.text.trim(),
        'contactPhone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
      };
      if (isEdit) {
        await _svc.updateCustomer(widget.customer!['id'], body);
      } else {
        await _svc.createCustomer(body);
      }
      Get.back();
      Get.snackbar('成功', isEdit ? '客户已更新' : '客户已创建',
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
      appBar: AppBar(
        title: Text(isEdit ? '编辑客户' : '新建客户'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final ok = await Get.dialog(AlertDialog(
                  title: const Text('确认删除'),
                  content: const Text('删除后不可恢复，确定删除该客户？'),
                  actions: [
                    TextButton(onPressed: () => Get.back(result: false), child: const Text('取消')),
                    TextButton(
                      onPressed: () => Get.back(result: true),
                      child: const Text('删除', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ));
                if (ok == true) {
                  try {
                    await _svc.deleteCustomer(widget.customer!['id']);
                    Get.back();
                    Get.snackbar('成功', '客户已删除', backgroundColor: Colors.green, colorText: Colors.white);
                  } catch (e) {
                    Get.snackbar('失败', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
                  }
                }
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '客户名称 *', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? '请输入客户名称' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _industryCtrl,
              decoration: const InputDecoration(labelText: '行业', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactCtrl,
              decoration: const InputDecoration(labelText: '联系人', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: '联系电话', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: '地址', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: '备注', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const SizedBox(height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(isEdit ? '保存修改' : '创建客户'),
            ),
          ],
        ),
      ),
    );
  }
}
