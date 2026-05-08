import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/product_model.dart';
import '../../data/models/sales_order_model.dart';
import '../../data/models/member_model.dart';
import '../../data/services/retail_service.dart';
import '../../data/services/member_service.dart';

class POSPage extends StatefulWidget {
  final List<CartItemModel>? initialItems;

  const POSPage({super.key, this.initialItems});

  @override
  State<POSPage> createState() => _POSPageState();
}

class _POSPageState extends State<POSPage> {
  final RetailService _retailService = RetailService();
  final MemberService _memberService = MemberService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _cashController = TextEditingController();

  List<CartItemModel> _cartItems = [];
  MemberModel? _member;
  String _selectedPaymentMethod = 'cash';
  List<ProductModel> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;
  bool _showMemberSearch = false;

  final List<Map<String, String>> _paymentMethods = [
    {'value': 'cash', 'label': '现金'},
    {'value': 'card', 'label': '刷卡'},
    {'value': 'wechat', 'label': '微信'},
    {'value': 'alipay', 'label': '支付宝'},
    {'value': 'transfer', 'label': '转账'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialItems != null && widget.initialItems!.isNotEmpty) {
      _cartItems = List.from(widget.initialItems!);
    }
    _discountController.text = '0';
    _cashController.text = '0';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _phoneController.dispose();
    _discountController.dispose();
    _cashController.dispose();
    super.dispose();
  }

  double get _totalAmount {
    return _cartItems.fold(0, (sum, item) => sum + item.subtotal);
  }

  double get _discount {
    return double.tryParse(_discountController.text) ?? 0;
  }

  double get _actualAmount {
    return _totalAmount - _discount;
  }

  double get _cashReceived {
    return double.tryParse(_cashController.text) ?? 0;
  }

  double get _change {
    return _cashReceived - _actualAmount;
  }

  int get _totalPoints {
    if (_member == null) return 0;
    return (_actualAmount ~/ 10);
  }

  Future<void> _searchProducts(String keyword) async {
    if (keyword.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _retailService.getProducts(keyword: keyword);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _searchMember(String phone) async {
    if (phone.length < 11) return;

    try {
      final member = await _memberService.getMemberByPhone(phone);
      setState(() => _member = member);
      if (member != null) {
        Get.snackbar('会员找到', '${member.memberName} (${member.memberLevel})',
            backgroundColor: AppColors.success, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('提示', '未找到该会员', backgroundColor: AppColors.warning);
    }
  }

  void _addToCart(ProductModel product) {
    setState(() {
      final existingIndex = _cartItems.indexWhere((item) => item.product.id == product.id);
      if (existingIndex >= 0) {
        _cartItems[existingIndex].quantity++;
      } else {
        _cartItems.add(CartItemModel(product: product));
      }
      _searchResults = [];
      _searchController.clear();
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      if (_cartItems[index].quantity > 1) {
        _cartItems[index].quantity--;
      } else {
        _cartItems.removeAt(index);
      }
    });
  }

  void _clearCart() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空购物车吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _cartItems.clear());
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCheckout() async {
    if (_cartItems.isEmpty) {
      Get.snackbar('提示', '购物车为空', backgroundColor: AppColors.warning);
      return;
    }

    if (_actualAmount <= 0) {
      Get.snackbar('提示', '订单金额必须大于0', backgroundColor: AppColors.warning);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final order = await _retailService.createSalesOrder(
        items: _cartItems,
        customerId: _member?.id,
        customerName: _member?.memberName,
        customerPhone: _member?.phone ?? _phoneController.text,
        discountAmount: _discount,
        paymentMethod: _selectedPaymentMethod,
      );

      if (_selectedPaymentMethod != 'wechat' && _selectedPaymentMethod != 'alipay') {
        await _retailService.payOrder(order.id, _selectedPaymentMethod);
      }

      setState(() => _isLoading = false);
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('收款成功'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 60),
              const SizedBox(height: 16),
              Text('订单号: ${order.orderNo ?? order.id}'),
              Text('实收金额: ¥${_actualAmount.toStringAsFixed(2)}'),
              if (_change > 0) Text('找零: ¥${_change.toStringAsFixed(2)}'),
              if (_member != null) Text('积分: +$_totalPoints'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Get.back();
              },
              child: const Text('完成'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('错误', '创建订单失败: $e', backgroundColor: AppColors.error);
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
        title: const Text('收银台', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          if (_cartItems.isNotEmpty)
            TextButton(
              onPressed: _clearCart,
              child: const Text('清空', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: _buildLeftPanel(),
          ),
          Expanded(
            flex: 2,
            child: _buildRightPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索商品名称/编码/条码',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: _searchProducts,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  hintText: '会员手机号',
                  prefixIcon: const Icon(Icons.phone),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => _searchMember(_phoneController.text),
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                keyboardType: TextInputType.phone,
                onSubmitted: _searchMember,
              ),
            ],
          ),
        ),
        if (_searchResults.isNotEmpty)
          Container(
            color: Colors.white,
            height: 200,
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final product = _searchResults[index];
                return ListTile(
                  leading: product.imageUrl != null
                      ? Image.network(product.imageUrl!, width: 40, height: 40, fit: BoxFit.cover)
                      : const Icon(Icons.image),
                  title: Text(product.productName),
                  subtitle: Text('${product.brand ?? ''} ¥${product.retailPrice?.toStringAsFixed(2) ?? '-'}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle, color: AppColors.primary),
                    onPressed: () => _addToCart(product),
                  ),
                );
              },
            ),
          ),
        if (_member != null)
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_member!.memberName ?? '会员', style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${_member!.memberLevel ?? ''} 积分:${_member!.availablePoints ?? 0}'),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => setState(() => _member = null),
                ),
              ],
            ),
          ),
        Expanded(
          child: _cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 80, color: AppColors.textHint.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text('购物车为空', style: TextStyle(color: AppColors.textHint)),
                      const SizedBox(height: 8),
                      Text('搜索商品或扫描条码添加', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _cartItems.length,
                  itemBuilder: (context, index) {
                    final item = _cartItems[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.product.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text(
                                    '¥${item.product.retailPrice?.toStringAsFixed(2) ?? '-'} x ${item.quantity}',
                                    style: TextStyle(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '¥${item.subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                              onPressed: () => _removeFromCart(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRightPanel() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('商品金额', style: TextStyle(color: Colors.white)),
                Text(
                  '¥${_totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputRow('折扣', _discountController, '¥', onChanged: (v) => setState(() {})),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildInfoRow('应付金额', '¥${_actualAmount.toStringAsFixed(2)}', isLarge: true),
                  const SizedBox(height: 16),
                  const Text('支付方式', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _paymentMethods.map((pm) {
                      final isSelected = _selectedPaymentMethod == pm['value'];
                      return ChoiceChip(
                        label: Text(pm['label']!),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedPaymentMethod = pm['value']!);
                          }
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedPaymentMethod == 'cash') ...[
                    _buildInputRow('收款', _cashController, '¥', onChanged: (v) => setState(() {})),
                    const SizedBox(height: 12),
                    _buildInfoRow('找零', '¥${_change.toStringAsFixed(2)}', isHighlight: _change > 0),
                  ],
                  if (_member != null) ...[
                    const Divider(),
                    _buildInfoRow('获得积分', '+$_totalPoints'),
                  ],
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        '确认收款 ¥${_actualAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow(String label, TextEditingController controller, String prefix,
      {Function(String)? onChanged}) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              prefixText: prefix,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLarge = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: isLarge ? 24 : 16,
              fontWeight: FontWeight.bold,
              color: isHighlight ? AppColors.error : (isLarge ? AppColors.error : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
