import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // 主题色
  static const Color primary = Color(0xFF1890FF);
  static const Color primaryDark = Color(0xFF096DD9);
  static const Color primaryLight = Color(0xFF40A9FF);

  // 背景色
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // 文字色
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF999999);
  static const Color textWhite = Color(0xFFFFFFFF);

  // 状态色
  static const Color statusPending = Color(0xFFFAAD14);   // 待派单 - 黄色
  static const Color statusAssigned = Color(0xFF1890FF);  // 已派单 - 蓝色
  static const Color statusInProgress = Color(0xFF52C41A); // 进行中 - 绿色
  static const Color statusCompleted = Color(0xFF8C8C8C);  // 已完成 - 灰色
  static const Color statusCancelled = Color(0xFFFF4D4F); // 已取消 - 红色

  // 功能色
  static const Color success = Color(0xFF52C41A);
  static const Color warning = Color(0xFFFAAD14);
  static const Color error = Color(0xFFFF4D4F);
  static const Color info = Color(0xFF1890FF);

  // 分割线
  static const Color divider = Color(0xFFE8E8E8);

  static Color getStatusColor(int status) {
    switch (status) {
      case 1:
        return statusPending;
      case 2:
        return statusAssigned;
      case 3:
        return statusInProgress;
      case 4:
        return statusCompleted;
      case 5:
        return statusCancelled;
      default:
        return textSecondary;
    }
  }

  static String getStatusText(int status) {
    switch (status) {
      case 1:
        return '待派单';
      case 2:
        return '已派单';
      case 3:
        return '进行中';
      case 4:
        return '已完成';
      case 5:
        return '已取消';
      default:
        return '未知';
    }
  }
}
