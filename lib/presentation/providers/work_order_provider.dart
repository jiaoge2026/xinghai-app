import 'package:flutter/material.dart';
import '../../data/services/work_order_service.dart';
import '../../data/models/work_order_model.dart';

class WorkOrderProvider extends ChangeNotifier {
  final WorkOrderService _workOrderService = WorkOrderService();

  List<WorkOrderModel> _workOrders = [];
  WorkOrderModel? _currentWorkOrder;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  List<WorkOrderModel> get workOrders => _workOrders;
  WorkOrderModel? get currentWorkOrder => _currentWorkOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> loadWorkOrders({
    int? status,
    int? engineerId,
    String? keyword,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _workOrders = [];
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final list = await _workOrderService.getPage(
        page: _currentPage,
        status: status,
        engineerId: engineerId,
        keyword: keyword,
      );

      if (list.length < 20) {
        _hasMore = false;
      }

      if (refresh) {
        _workOrders = list;
      } else {
        _workOrders.addAll(list);
      }
      _currentPage++;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadWorkOrderDetail(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentWorkOrder = await _workOrderService.getDetail(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStatus(int id, int status, {String? remark}) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _workOrderService.updateStatus(id, status, remark: remark);
      if (_currentWorkOrder != null && _currentWorkOrder!.id == id) {
        _currentWorkOrder = _currentWorkOrder!.copyWith(status: status);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeWorkOrder({
    required int id,
    required double workHours,
    required double travelFee,
    double materialFee = 0,
    String? remark,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _workOrderService.complete(
        id: id,
        workHours: workHours,
        travelFee: travelFee,
        materialFee: materialFee,
        remark: remark,
      );
      if (_currentWorkOrder != null && _currentWorkOrder!.id == id) {
        _currentWorkOrder = _currentWorkOrder!.copyWith(
          status: 4,
          workHours: workHours,
          travelFee: travelFee,
          materialFee: materialFee,
          remark: remark,
        );
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clear() {
    _workOrders = [];
    _currentWorkOrder = null;
    _currentPage = 1;
    _hasMore = true;
    _error = null;
    notifyListeners();
  }
}
