import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/storage_util.dart';
import '../providers/auth_provider.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'package:flutter/foundation.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkLoginAndNavigate();
  }

  Future<void> _checkLoginAndNavigate() async {
    print('[SplashPage] _checkLoginAndNavigate() start');
    print('[SplashPage] baseUrl=${AppConstants.baseUrl}');
    // 延迟一下以显示启动页
    await Future.delayed(const Duration(milliseconds: 800));

    final token = await StorageUtil.get(AppConstants.tokenKey);
    print('[SplashPage] token from storage: ${token != null ? "exists(${token.length})" : "null"}');

    // Provider 和 GetX 混用：用 Provider.of 读取（因为 AuthProvider 是 Provider 注册的）
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (token != null && token.isNotEmpty) {
      // 有Token，尝试加载用户信息
      try {
        print('[SplashPage] calling checkLoginStatus()...');
        await authProvider.checkLoginStatus();
        print('[SplashPage] checkLoginStatus done, isLoggedIn=${authProvider.isLoggedIn}');
        if (authProvider.isLoggedIn) {
          print('[SplashPage] navigating to HomePage');
          Get.offAll(() => const HomePage());
        } else {
          print('[SplashPage] not logged in, navigating to LoginPage');
          Get.offAll(() => const LoginPage());
        }
      } catch (e) {
        print('[SplashPage] checkLoginStatus exception: $e');
        // Token无效，跳转登录
        Get.offAll(() => const LoginPage());
      }
    } else {
      // 无Token，跳转登录
      print('[SplashPage] no token, navigating to LoginPage');
      Get.offAll(() => const LoginPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.home_work_outlined,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            // App Name
            const Text(
              AppConstants.appName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '现场服务管理系统',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 48),
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
