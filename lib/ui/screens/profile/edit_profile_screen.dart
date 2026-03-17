import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../data/models/user_profile_model.dart';
import '../../../providers/profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfileModel currentProfile;

  const EditProfileScreen({super.key, required this.currentProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  // Xử lý ảnh
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // ── Color tokens ──────────
  static const Color _bg           = Color(0xFFF5F7FA);
  static const Color _surface      = Color(0xFFFFFFFF);
  static const Color _primary      = Color(0xFF2563EB);
  static const Color _primaryLight = Color(0xFFEFF6FF);
  static const Color _textPrimary  = Color(0xFF111827);
  static const Color _textSecondary= Color(0xFF6B7280);
  static const Color _border       = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    _nameController = TextEditingController(text: widget.currentProfile.fullName);
    _phoneController = TextEditingController(text: widget.currentProfile.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ── Logic Chọn Ảnh ──────────────────────────────────────
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // ── Logic Submit qua Provider ──────────────────────
  Future<void> _submitUpdate() async {
    FocusScope.of(context).unfocus();

    if (_nameController.text.trim().isEmpty) {
      _snack("Họ tên không được để trống", isError: true);
      return;
    }

    // Đẩy toàn bộ dữ liệu (Text + File) cho Provider xử lý
    final success = await Provider.of<ProfileProvider>(context, listen: false).updateProfileData(
      fullName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      avatarFile: _imageFile, // Có thể null nếu user không đổi ảnh
    );

    if (mounted) {
      if (success) {
        _snack("Cập nhật thông tin thành công! 🎉");
        Navigator.pop(context);
      } else {
        _snack("Cập nhật thất bại. Vui lòng kiểm tra lại mạng.", isError: true);
      }
    }
  }

  // ── Build UI ────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ProfileProvider>().isLoading;

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildAvatarPicker(),
                  const SizedBox(height: 36),

                  _sectionLabel("Thông tin cá nhân"),
                  const SizedBox(height: 10),
                  _buildInputCard(),
                  const SizedBox(height: 40),

                  _buildSubmitButton(isLoading),
                ],
              ),
            ),
          ),

          if (isLoading)
            Container(
              color: Colors.white.withOpacity(0.6),
              child: const Center(
                child: CircularProgressIndicator(color: _primary, strokeWidth: 3),
              ),
            ),
        ],
      ),
    );
  }

  // ── Components ──────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: _surface,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _textPrimary),
      onPressed: () => Navigator.pop(context),
    ),
    title: const Text(
      "Chỉnh sửa hồ sơ",
      style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3),
    ),
    centerTitle: true,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: _border),
    ),
  );

  Widget _sectionLabel(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textSecondary, letterSpacing: 0.2),
    ),
  );

  Widget _buildAvatarPicker() => GestureDetector(
    onTap: _pickImage,
    child: Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: _primaryLight,
            shape: BoxShape.circle,
            border: Border.all(color: _border, width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            image: _imageFile != null
                ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                : (widget.currentProfile.avatarUrl != null && widget.currentProfile.avatarUrl!.isNotEmpty)
                ? DecorationImage(image: NetworkImage(widget.currentProfile.avatarUrl!), fit: BoxFit.cover)
                : null,
          ),
          child: (_imageFile == null && (widget.currentProfile.avatarUrl == null || widget.currentProfile.avatarUrl!.isEmpty))
              ? const Icon(Icons.person_rounded, size: 50, color: _primary)
              : null,
        ),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _primary,
            shape: BoxShape.circle,
            border: Border.all(color: _surface, width: 3),
          ),
          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
        ),
      ],
    ),
  );

  Widget _buildInputCard() => Container(
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Column(
      children: [
        _buildTextField(
          controller: _nameController,
          label: "Họ và tên",
          icon: Icons.badge_rounded,
        ),
        Container(height: 1, color: _border),
        _buildTextField(
          controller: _phoneController,
          label: "Số điện thoại",
          icon: Icons.phone_android_rounded,
          keyboardType: TextInputType.phone,
        ),
      ],
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: _textPrimary, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _textSecondary, fontSize: 14),
        prefixIcon: Icon(icon, color: _primary, size: 20),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildSubmitButton(bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : _submitUpdate,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity, height: 56,
        decoration: BoxDecoration(
          color: isLoading ? _border : _primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLoading ? [] : [
            BoxShadow(color: _primary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : const Text("LƯU THAY ĐỔI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5)),
        ),
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}