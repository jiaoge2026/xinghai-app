import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/delivery_order_model.dart';
import '../../data/services/delivery_service.dart';

class DeliveryDetailPage extends StatefulWidget {
  const DeliveryDetailPage({super.key});

  @override
  State<DeliveryDetailPage> createState() => _DeliveryDetailPageState();
}

class _DeliveryDetailPageState extends State<DeliveryDetailPage> {
  late int _orderId;
  final DeliveryService _deliveryService = DeliveryService();
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  DeliveryOrderModel? _order;
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<File> _photoFiles = [];

  @override
  void initState() {
    super.initState();
    _orderId = Get.arguments as int;
    _loadDetail();
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    try {
      final order = await _deliveryService.getDeliveryOrderDetail(_orderId);
      setState(() {
        _order = order;
        _recipientController.text = order.recipientName ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败：$e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _photoFiles.add(File(image.path));
      });
    }
  }

  Future<void> _pickPhoto() async {
    final List<XFile> images = await _imagePicker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      setState(() {
        _photoFiles.addAll(images.map((e) => File(e.path)));
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photoFiles.removeAt(index);
    });
  }

  Future<void> _handleStatusAction() async {
    if (_order == null) return;

    setState(() => _isSubmitting = true);

    try {
      switch (_order!.status) {
        case 1:
          await _deliveryService.confirmPickup(_orderId);
          break;
        case 2:
          await _deliveryService.startDelivery(_orderId);
          break;
        case 3:
          await _deliveryService.confirmArrival(_orderId);
          break;
        case 4:
          await _showCompleteDialog();
          return;
        default:
          break;
      }

      await _loadDetail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作成功'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败：$e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showCompleteDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('完成配送'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('签收人:', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _recipientController,
                decoration: const InputDecoration(
                  hintText: '请输入签收人姓名',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 16),
              const Text('签收照片:', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._photoFiles.asMap().entries.map((entry) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            entry.value,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _removePhoto(entry.key),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, color: AppColors.textHint),
                          SizedBox(height: 4),
                          Text('添加照片', style: TextStyle(fontSize: 10, color: AppColors.textHint)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('备注:', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _remarkController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: '可选填写备注',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('提交', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      await _completeDelivery();
    }
  }

  Future<void> _completeDelivery() async {
    if (_order == null) return;

    setState(() => _isSubmitting = true);

    try {
      await _deliveryService.completeDelivery(
        _orderId,
        recipientName: _recipientController.text.isNotEmpty ? _recipientController.text : null,
        remark: _remarkController.text.isNotEmpty ? _remarkController.text : null,
      );

      await _loadDetail();
      _photoFiles.clear();
      _recipientController.clear();
      _remarkController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('配送完成'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('完成失败：$e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  String _getActionButtonText() {
    if (_order == null) return '';
    switch (_order!.status) {
      case 1:
        return '确认取货';
      case 2:
        return '开始配送';
      case 3:
        return '确认到达';
      case 4:
        return '拍照签收';
      default:
        return '';
    }
  }

  bool _showActionButton() {
    if (_order == null) return false;
    return [1, 2, 3, 4].contains(_order!.status);
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return AppColors.warning;
      case 2:
        return AppColors.info;
      case 3:
        return AppColors.primary;
      case 4:
        return AppColors.success;
      case 5:
        return AppColors.textHint;
      default:
        return AppColors.textSecondary;
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
        title: const Text('配送单详情', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('加载失败'))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatusCard(),
                            const SizedBox(height: 16),
                            _buildDeliveryInfo(),
                            const SizedBox(height: 16),
                            _buildGoodsInfo(),
                            if (_order!.remark != null && _order!.remark!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildRemark(),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (_showActionButton()) _buildBottomAction(),
                  ],
                ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor(_order!.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.local_shipping,
                color: _getStatusColor(_order!.status),
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _order!.statusText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(_order!.status),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '配送单号: ${_order!.deliveryNo}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '配送信息',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.person, '客户名称', _order!.customerName),
            _buildInfoRow(Icons.phone, '客户电话', _order!.customerPhone),
            _buildInfoRow(Icons.location_on, '配送地址', _order!.customerAddress),
            if (_order!.contactName != null)
              _buildInfoRow(Icons.contact_phone, '联系人', _order!.contactName!),
            if (_order!.pickupTime != null)
              _buildInfoRow(Icons.access_time, '取货时间', _order!.pickupTime!),
            if (_order!.recipientName != null)
              _buildInfoRow(Icons.assignment_turned_in, '签收人', _order!.recipientName!),
          ],
        ),
      ),
    );
  }

  Widget _buildGoodsInfo() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '商品信息',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.inventory_2, '总数量', '${_order!.totalQuantity.toStringAsFixed(1)}'),
            _buildInfoRow(Icons.scale, '总重量', '${_order!.totalWeight.toStringAsFixed(1)} kg'),
          ],
        ),
      ),
    );
  }

  Widget _buildRemark() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '备注',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              _order!.remark!,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textHint),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 14, color: AppColors.textHint),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _handleStatusAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    _getActionButtonText(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }
}
