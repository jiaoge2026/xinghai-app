import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/member_service.dart';

class MemberRegisterPage extends StatefulWidget {
  const MemberRegisterPage({super.key});

  @override
  State<MemberRegisterPage> createState() => _MemberRegisterPageState();
}

class _MemberRegisterPageState extends State<MemberRegisterPage> {
  final MemberService _memberService = MemberService();
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _idCardController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String _gender = 'male';
  DateTime? _birthday;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _idCardController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final member = await _memberService.registerMember(
        phone: _phoneController.text,
        memberName: _nameController.text,
        gender: _gender,
        birthday: _birthday?.toIso8601String().split('T')[0],
        email: _emailController.text.isEmpty ? null : _emailController.text,
        idCard: _idCardController.text.isEmpty ? null : _idCardController.text,
        address: _addressController.text.isEmpty ? null : _addressController.text,
      );

      setState(() => _isLoading = false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('注册成功'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 60),
              const SizedBox(height: 16),
              Text('会员号: ${member.memberNo ?? member.id}'),
              Text('姓名: ${member.memberName}'),
              Text('手机: ${member.phone}'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Get.back();
              },
              child: const Text('确定'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('错误', '注册失败: $e', backgroundColor: AppColors.error);
    }
  }

  Future<void> _selectBirthday() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _birthday = date);
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
        title: const Text('会员注册', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('基本信息'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _phoneController,
                label: '手机号 *',
                hint: '请输入手机号',
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.isEmpty) return '请输入手机号';
                  if (v.length != 11) return '手机号格式不正确';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _nameController,
                label: '姓名 *',
                hint: '请输入姓名',
                validator: (v) {
                  if (v == null || v.isEmpty) return '请输入姓名';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildSectionTitle('详细信息'),
              const SizedBox(height: 12),
              _buildGenderSelector(),
              const SizedBox(height: 12),
              _buildDatePicker(),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _emailController,
                label: '邮箱',
                hint: '请输入邮箱（选填）',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _idCardController,
                label: '身份证号',
                hint: '请输入身份证号（选填）',
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _addressController,
                label: '地址',
                hint: '请输入地址（选填）',
                maxLines: 2,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('立即注册', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text('性别', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _gender = 'male'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _gender == 'male' ? AppColors.primary.withOpacity(0.1) : Colors.white,
                    border: Border.all(
                      color: _gender == 'male' ? AppColors.primary : AppColors.divider,
                      width: _gender == 'male' ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.male,
                        color: _gender == 'male' ? AppColors.primary : AppColors.textHint,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '男',
                        style: TextStyle(
                          color: _gender == 'male' ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: _gender == 'male' ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _gender = 'female'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _gender == 'female' ? AppColors.primary.withOpacity(0.1) : Colors.white,
                    border: Border.all(
                      color: _gender == 'female' ? AppColors.primary : AppColors.divider,
                      width: _gender == 'female' ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.female,
                        color: _gender == 'female' ? AppColors.primary : AppColors.textHint,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '女',
                        style: TextStyle(
                          color: _gender == 'female' ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: _gender == 'female' ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text('生日', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ),
        GestureDetector(
          onTap: _selectBirthday,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _birthday != null
                      ? '${_birthday!.year}-${_birthday!.month.toString().padLeft(2, '0')}-${_birthday!.day.toString().padLeft(2, '0')}'
                      : '请选择生日（选填）',
                  style: TextStyle(
                    color: _birthday != null ? AppColors.textPrimary : AppColors.textHint,
                  ),
                ),
                Icon(Icons.calendar_today, color: AppColors.textHint, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
