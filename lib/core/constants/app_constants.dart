class AppConstants {
  AppConstants._();

  static const String appName = '星海ERP';
  static const String appVersion = '1.0.0';

  // API基础地址（根路径，service层补全完整路径）
  static const String baseUrl = 'http://47.103.11.151:38080';

  // 认证相关
  static const String tokenKey = 'auth_token';
  static const String userKey = 'current_user';

  // 工单状态
  static const int statusPending = 1;    // 待派单
  static const int statusAssigned = 2;   // 已派单
  static const int statusInProgress = 3; // 进行中
  static const int statusCompleted = 4;  // 已完成
  static const int statusCancelled = 5;  // 已取消

  // 工程师接单状态
  static const int engineerAccepting = 1; // 接单
  static const int engineerPaused = 2;    // 暂停

  // 分页默认值
  static const int defaultPageSize = 20;
}
