import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/user_profile_model.dart';
import '../../../providers/profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfileModel currentProfile;

  const EditProfileScreen({super.key, required this.currentProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _avatarController;

  @override
  void initState() {
    super.initState();
    // Điền sẵn thông tin cũ vào form
    _nameController = TextEditingController(text: widget.currentProfile.fullName);
    _phoneController = TextEditingController(text: widget.currentProfile.phoneNumber ?? '');
    _avatarController = TextEditingController(text: widget.currentProfile.avatarUrl ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  void _submitUpdate() async {
    // Ẩn bàn phím
    FocusScope.of(context).unfocus();

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Họ tên không được để trống")));
      return;
    }

    // Tạo model chứa dữ liệu mới
    final updatedData = UserProfileModel(
      id: widget.currentProfile.id,
      email: widget.currentProfile.email, // Email thường không cho sửa, giữ nguyên
      fullName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      avatarUrl: _avatarController.text.trim(),
      role: widget.currentProfile.role,
      status: widget.currentProfile.status,
    );

    // Gọi Provider để push API
    final success = await Provider.of<ProfileProvider>(context, listen: false).updateProfile(updatedData);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cập nhật thông tin thành công!")));
        Navigator.pop(context); // Trở về màn hình Profile
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cập nhật thất bại. Vui lòng thử lại.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ProfileProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cập nhật thông tin"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Demo hiển thị Avatar tạm thời
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _avatarController.text.isNotEmpty
                      ? NetworkImage(_avatarController.text)
                      : const NetworkImage("https://via.placeholder.com/150"),
                  onBackgroundImageError: (_, __) {},
                ),
                const SizedBox(height: 30),

                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Họ và tên",
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Số điện thoại",
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _avatarController,
                  decoration: const InputDecoration(
                    labelText: "Đường dẫn ảnh đại diện (URL)",
                    prefixIcon: Icon(Icons.image),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isLoading ? null : _submitUpdate,
                    child: const Text("LƯU THAY ĐỔI", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          // Hiển thị loading đè lên màn hình khi đang gọi API
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            )
        ],
      ),
    );
  }
}