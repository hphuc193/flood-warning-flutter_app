import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../providers/profile_provider.dart';
import 'edit_profile_screen.dart';
import 'saved_locations_screen.dart';
import '../checklist_screen.dart';
import '../evacuation_guide_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Tải dữ liệu người dùng khi mở Tab này
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(context, listen: false).fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Cá nhân"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          if (profileProvider.isLoading && profileProvider.profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (profileProvider.profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Không thể tải thông tin cá nhân."),
                  ElevatedButton(
                    onPressed: () => profileProvider.fetchProfile(),
                    child: const Text("Thử lại"),
                  )
                ],
              ),
            );
          }

          final user = profileProvider.profile!;

          return SingleChildScrollView(
            child: Column(
              children: [
                // HEADER INFO
                Container(
                  color: Colors.blueAccent,
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 30, top: 20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                        child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                            ? const Icon(Icons.person, size: 50, color: Colors.blueAccent)
                            : null,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        user.fullName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        user.email,
                        style: const TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // MENU OPTIONS
                _buildMenuOption(
                  icon: Icons.edit,
                  title: "Cập nhật thông tin",
                  subtitle: "Thay đổi tên, số điện thoại, ảnh đại diện",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(currentProfile: user),
                      ),
                    );
                  },
                ),

                _buildMenuOption(
                  icon: Icons.my_location,
                  title: "Vị trí quan tâm (Cảnh báo)",
                  subtitle: "Quản lý nơi ở, nơi làm việc để nhận thông báo",
                  iconColor: Colors.redAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SavedLocationsScreen(),
                      ),
                    );
                  },
                ),

                _buildMenuOption(
                  icon: Icons.fact_check_outlined,
                  title: "Checklist chuẩn bị ứng phó",
                  subtitle: "Danh sách các việc cần làm, vật dụng cần thiết khi có lũ",
                  iconColor: Colors.orange, // Dùng màu cam/vàng để nhấn mạnh cảnh báo
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChecklistScreen(),
                      ),
                    );
                  },
                ),

                _buildMenuOption(
                  icon: Icons.directions_run_rounded,
                  title: "Hướng dẫn sơ tán an toàn",
                  subtitle: "Các bước di chuyển và quy tắc an toàn khi có bão lũ",
                  iconColor: Colors.teal, // Dùng màu xanh mòng két (teal) tạo cảm giác an toàn, hy vọng
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EvacuationGuideScreen(),
                      ),
                    );
                  },
                ),

                const Divider(height: 30),

                _buildMenuOption(
                  icon: Icons.logout,
                  title: "Đăng xuất",
                  iconColor: Colors.grey,
                  onTap: () {
                    // TODO: Xử lý logic đăng xuất (Xóa token, chuyển về LoginScreen)
                    _showLogoutConfirm(context);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    String? subtitle,
    Color iconColor = Colors.blueAccent,
    required VoidCallback onTap
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutConfirm(BuildContext context) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Đăng xuất"),
          content: const Text("Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
            TextButton(
                onPressed: () async {
                  // 1. Đóng hộp thoại (Dialog)
                  Navigator.pop(ctx);

                  // Hiển thị vòng xoay loading (tùy chọn để UX tốt hơn)
                  showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(child: CircularProgressIndicator())
                  );

                  try {
                    // 2. Xóa dữ liệu phiên bản đăng nhập ở Local Storage
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear(); // Hoặc xóa cụ thể: await prefs.remove('token');

                    // 3. (QUAN TRỌNG) Đăng xuất khỏi Google Sign In / Firebase (Bỏ comment nếu bạn đang dùng)
                    // await FirebaseAuth.instance.signOut();
                    // await GoogleSignIn().signOut();

                    // 4. Chuyển về màn hình Đăng nhập và xóa sạch lịch sử Route
                    if (context.mounted) {
                      // Tắt vòng xoay loading
                      Navigator.pop(context);

                      // Chuyển trang & Xóa route cũ
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(), // Đổi thành tên class Màn hình đăng nhập của bạn
                        ),
                            (Route<dynamic> route) => false, // Trả về false sẽ xóa toàn bộ các trang trước đó
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context); // Tắt loading nếu lỗi
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Lỗi đăng xuất: $e")),
                      );
                    }
                  }
                },
                child: const Text("Đăng xuất", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
            ),
          ],
        )
    );
  }
}