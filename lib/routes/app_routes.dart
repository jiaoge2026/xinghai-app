import 'package:get/get.dart';
import '../presentation/pages/login_page.dart';
import '../presentation/pages/home_page.dart';
import '../presentation/pages/work_order_list_page.dart';
import '../presentation/pages/work_order_detail_page.dart';
import '../presentation/pages/work_order_complete_page.dart';
import '../presentation/pages/notification_page.dart';
import '../presentation/pages/my_page.dart';
import '../presentation/pages/splash_page.dart';
import '../presentation/pages/project_list_page.dart';
import '../presentation/pages/attendance_page.dart';
import '../presentation/pages/leave_list_page.dart';
import '../presentation/pages/leave_apply_page.dart';
import '../presentation/pages/salary_page.dart';
import '../presentation/pages/delivery_list_page.dart';
import '../presentation/pages/delivery_detail_page.dart';
import '../presentation/pages/opportunity_list_page.dart';
import '../presentation/pages/opportunity_detail_page.dart';
import '../presentation/pages/opportunity_form_page.dart';
import '../presentation/pages/customer_follow_up_page.dart';
import '../presentation/pages/customer_list_page.dart';
import '../presentation/pages/customer_form_page.dart';
import '../presentation/pages/quote_list_page.dart';
import '../presentation/pages/quote_form_page.dart';
import '../presentation/pages/project_order_list_page.dart';
import '../presentation/pages/project_order_detail_page.dart';
import '../presentation/pages/receivable_list_page.dart';
import '../presentation/pages/call_record_list_page.dart';
import '../presentation/pages/call_record_detail_page.dart';
import '../presentation/pages/callback_request_page.dart';
import '../presentation/pages/product_list_page.dart';
import '../presentation/pages/product_detail_page.dart';
import '../presentation/pages/pos_page.dart';
import '../presentation/pages/sales_order_list_page.dart';
import '../presentation/pages/member_register_page.dart';
import '../presentation/pages/member_detail_page.dart';
import '../presentation/pages/point_record_page.dart';
import '../presentation/pages/coupon_list_page.dart';
import '../presentation/pages/dashboard_page.dart';
import '../presentation/pages/fsm_dashboard_page.dart';
import '../presentation/pages/finance_dashboard_page.dart';
import '../presentation/pages/inventory_dashboard_page.dart';
import '../presentation/pages/engineer_ranking_page.dart';
import '../presentation/pages/ai_chat_page.dart';
import '../presentation/pages/ai_session_list_page.dart';
import '../presentation/pages/approval_list_page.dart';
import '../presentation/pages/approval_detail_page.dart';
import '../presentation/pages/my_application_page.dart';

class AppRoutes {
  AppRoutes._();

  // 路由名称常量
  static const String splash = '/splash';
  static const String login = '/login';
  static const String home = '/home';
  static const String workOrderList = '/work-order/list';
  static const String workOrderDetail = '/work-order/detail';
  static const String workOrderComplete = '/work-order/complete';
  static const String notification = '/notification';
  static const String my = '/my';
  static const String projectList = '/project/list';
  static const String projectDetail = '/project/detail';
  static const String attendance = '/attendance';
  static const String leaveList = '/leave_list';
  static const String leaveApply = '/leave_apply';
  static const String salary = '/salary';

  // 物流配送路由
  static const String deliveryList = '/delivery_list';
  static const String deliveryDetail = '/delivery_detail';

  // CRM路由
  static const String opportunityList = '/opportunity_list';
  static const String opportunityDetail = '/opportunity_detail';
  static const String opportunityForm = '/opportunity_form';
  static const String customerFollowUp = '/customer_follow_up';

  // 销售路由（工程项目）
  static const String customerList = '/sales_customer_list';
  static const String customerForm = '/sales_customer_form';
  static const String quoteList = '/sales_quote_list';
  static const String quoteForm = '/sales_quote_form';
  static const String projectOrderList = '/sales_project_order_list';
  static const String projectOrderDetail = '/project_order_detail';
  static const String receivableList = '/sales_receivable_list';

  // 呼叫中心路由
  static const String callRecordList = '/call_record_list';
  static const String callRecordDetail = '/call_record_detail';
  static const String callbackRequest = '/callback_request';

  // 零售门店路由
  static const String productList = '/product_list';
  static const String productDetail = '/product_detail';
  static const String pos = '/pos';
  static const String salesOrders = '/sales_orders';

  // 会员路由
  static const String memberRegister = '/member_register';
  static const String memberDetail = '/member_detail';
  static const String pointRecords = '/point_records';
  static const String couponList = '/coupon_list';

  // 驾驶舱路由
  static const String dashboard = '/dashboard';
  static const String fsmDashboard = '/fsm_dashboard';
  static const String financeDashboard = '/finance_dashboard';
  static const String inventoryDashboard = '/inventory_dashboard';
  static const String engineerRanking = '/engineer_ranking';

  // AI助手路由
  static const String aiChat = '/ai_chat';
  static const String aiSessions = '/ai_sessions';

  // 审批路由
  static const String approvalList = '/approval_list';
  static const String approvalDetail = '/approval_detail';
  static const String myApplications = '/my_applications';

  // GetX路由配置
  static final List<GetPage> pages = [
    GetPage(
      name: splash,
      page: () => const SplashPage(),
      transition: Transition.fade,
    ),
    GetPage(
      name: login,
      page: () => const LoginPage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: home,
      page: () => const HomePage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: workOrderList,
      page: () => const WorkOrderListPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: workOrderDetail,
      page: () => const WorkOrderDetailPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: workOrderComplete,
      page: () => const WorkOrderCompletePage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: notification,
      page: () => const NotificationPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: my,
      page: () => const MyPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: projectList,
      page: () => const ProjectListPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: attendance,
      page: () => const AttendancePage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: leaveList,
      page: () => const LeaveListPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: leaveApply,
      page: () => const LeaveApplyPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: salary,
      page: () => const SalaryPage(),
      transition: Transition.rightToLeft,
    ),

    // 物流配送页面
    GetPage(
      name: deliveryList,
      page: () => const DeliveryListPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: deliveryDetail,
      page: () => const DeliveryDetailPage(),
      transition: Transition.rightToLeft,
    ),

    // CRM页面
    GetPage(
      name: opportunityList,
      page: () => const OpportunityListPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: opportunityDetail,
      page: () => const OpportunityDetailPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: opportunityForm,
      page: () => const OpportunityFormPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: customerFollowUp,
      page: () => const CustomerFollowUpPage(),
      transition: Transition.rightToLeft,
    ),

    // 工程项目销售页面
    GetPage(
      name: customerList,
      page: () => const CustomerListPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: customerForm,
      page: () {
        final c = Get.arguments as Map<String, dynamic>?;
        return CustomerFormPage(customer: c);
      },
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: quoteList,
      page: () => const QuoteListPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: quoteForm,
      page: () {
        final q = Get.arguments as Map<String, dynamic>?;
        return QuoteFormPage(quote: q);
      },
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: projectOrderList,
      page: () => const ProjectOrderListPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: projectOrderDetail,
      page: () => const ProjectOrderDetailPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: receivableList,
      page: () => const ReceivableListPage(),
      transition: Transition.rightToLeft,
    ),

    // 呼叫中心页面
    GetPage(
      name: callRecordList,
      page: () => const CallRecordListPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: callRecordDetail,
      page: () => const CallRecordDetailPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: callbackRequest,
      page: () => const CallbackRequestPage(),
      transition: Transition.rightToLeft,
    ),

    // 零售门店页面
    GetPage(
      name: productList,
      page: () => const ProductListPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: productDetail,
      page: () {
        final product = Get.arguments;
        return ProductDetailPage(product: product);
      },
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: pos,
      page: () => const POSPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: salesOrders,
      page: () => const SalesOrderListPage(),
      transition: Transition.rightToLeft,
    ),

    // 会员页面
    GetPage(
      name: memberRegister,
      page: () => const MemberRegisterPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: memberDetail,
      page: () {
        final memberId = Get.arguments as int;
        return MemberDetailPage(memberId: memberId);
      },
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: pointRecords,
      page: () {
        final memberId = Get.arguments as int;
        return PointRecordPage(memberId: memberId);
      },
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: couponList,
      page: () {
        final memberId = Get.arguments as int;
        return CouponListPage(memberId: memberId);
      },
      transition: Transition.rightToLeft,
    ),

    // 驾驶舱页面
    GetPage(
      name: dashboard,
      page: () => const DashboardPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: fsmDashboard,
      page: () => const FsmDashboardPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: financeDashboard,
      page: () => const FinanceDashboardPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: inventoryDashboard,
      page: () => const InventoryDashboardPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: engineerRanking,
      page: () => const EngineerRankingPage(),
      transition: Transition.rightToLeft,
    ),

    // AI助手页面
    GetPage(
      name: aiChat,
      page: () => const AIChatPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: aiSessions,
      page: () => const AISessionListPage(),
      transition: Transition.rightToLeft,
    ),

    // 审批页面
    GetPage(
      name: approvalList,
      page: () => const ApprovalListPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: approvalDetail,
      page: () {
        final instanceNo = Get.arguments as String;
        return ApprovalDetailPage(instanceNo: instanceNo);
      },
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: myApplications,
      page: () => const MyApplicationPage(),
      transition: Transition.rightToLeft,
    ),
  ];
}
