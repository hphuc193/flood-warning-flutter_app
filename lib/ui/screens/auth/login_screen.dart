import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../home/main_screen.dart';
import 'register_screen.dart';
import '../../../data/services/notification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  static const Color _primaryBlue = Color(0xFF1A56DB);
  static const Color _bgGray = Color(0xFFF4F6FA);
  static const Color _cardBorder = Color(0xFFE8EBF0);
  static const Color _textPrimary = Color(0xFF1A1A2E);
  static const Color _textSecondary = Color(0xFF8A94A6);

  // === XỬ LÝ ĐĂNG NHẬP GOOGLE ===
  void _handleGoogleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = await authProvider.loginWithGoogle(context);
    if (success && mounted) {
      NotificationService().updateDeviceTokenAndLocation();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  // === XỬ LÝ ĐĂNG NHẬP FACEBOOK ===
  void _handleFacebookLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = await authProvider.loginWithFacebook(context);
    if (success && mounted) {
      NotificationService().updateDeviceTokenAndLocation();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: _bgGray,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── HERO HEADER ──
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: _primaryBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 48,
                bottom: 40,
                left: 24,
                right: 24,
              ),
              child: Column(
                children: [
                  // --- THIẾT KẾ LẠI LOGO HIỆN ĐẠI ---
                  Container(
                    width: 84,
                    height: 84,
                    padding: const EdgeInsets.all(14), // Khoảng trắng an toàn cho logo
                    decoration: BoxDecoration(
                      color: Colors.white, // Nền trắng giúp logo nổi bật hoàn toàn
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/logo-removebg.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.water_drop_rounded,
                        size: 40,
                        color: _primaryBlue,
                      ),
                    ),
                  ),
                  // ------------------------------------
                  const SizedBox(height: 20),
                  const Text(
                      'Chào mừng trở lại',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600, // Tăng nhẹ độ đậm để nhìn khỏe khoắn hơn
                        color: Colors.white,
                        letterSpacing: -0.5,
                      )
                  ),
                  const SizedBox(height: 8),
                  Text(
                      'Đăng nhập để tiếp tục theo dõi thời tiết',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w400
                      )
                  ),
                ],
              ),
            ),

            // ── FORM CARD ──
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _cardBorder, width: 0.5),
                  // Thêm chút bóng mờ cho card form nhập liệu
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textPrimary)),
                    const SizedBox(height: 8),
                    _buildTextField(controller: _emailController, hint: 'example@email.com', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),

                    const SizedBox(height: 16),

                    const Text('Mật khẩu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textPrimary)),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _passwordController,
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: _textSecondary),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity, height: 50,
                      child: authProvider.isLoading
                          ? const Center(child: CircularProgressIndicator(color: _primaryBlue))
                          : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                        onPressed: () async {
                          bool success = await authProvider.login(_emailController.text, _passwordController.text, context);
                          if (!context.mounted) return;
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng nhập thành công!')));
                            NotificationService().updateDeviceTokenAndLocation();
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
                          }
                        },
                        child: const Text('Đăng nhập', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        const Expanded(child: Divider(color: _cardBorder, thickness: 1)),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Hoặc', style: TextStyle(fontSize: 12, color: _textSecondary))),
                        const Expanded(child: Divider(color: _cardBorder, thickness: 1)),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // --- NÚT ĐĂNG NHẬP GOOGLE ---
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _cardBorder, width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: Colors.white
                        ),
                        onPressed: authProvider.isLoading ? null : _handleGoogleLogin,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/google_logo.png', width: 22, height: 22, errorBuilder: (_,__,___) => const Icon(Icons.g_mobiledata, color: Colors.red)),
                            const SizedBox(width: 10),
                            const Text('Đăng nhập bằng Google', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _textPrimary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // --- NÚT ĐĂNG NHẬP FACEBOOK ---
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _cardBorder, width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: Colors.white
                        ),
                        onPressed: authProvider.isLoading ? null : _handleFacebookLogin,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/facebook_logo.png', width: 22, height: 22, errorBuilder: (_,__,___) => const Icon(Icons.facebook, color: Colors.blue)),
                            const SizedBox(width: 10),
                            const Text('Đăng nhập bằng Facebook', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _textPrimary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── ĐĂNG KÝ ──
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chưa có tài khoản?', style: TextStyle(fontSize: 14, color: _textSecondary)),
                  TextButton(
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap
                    ),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: const Text('Đăng ký ngay', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _primaryBlue)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, TextInputType keyboardType = TextInputType.text, bool obscure = false, Widget? suffixIcon}) {
    return TextField(
      controller: controller, keyboardType: keyboardType, obscureText: obscure, style: const TextStyle(fontSize: 14, color: _textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: _textSecondary),
        prefixIcon: Icon(icon, size: 20, color: _textSecondary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _bgGray,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _cardBorder, width: 1)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _cardBorder, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primaryBlue, width: 1.5)),
      ),
    );
  }
}