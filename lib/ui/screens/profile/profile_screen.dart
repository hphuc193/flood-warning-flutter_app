import 'package:flood_warning_mobile_v1/ui/screens/profile/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../providers/network_sync_provider.dart';
import '../../widgets/offline_banner.dart';

import '../auth/login_screen.dart';
import '../../../providers/profile_provider.dart';
import 'edit_profile_screen.dart';
import 'saved_locations_screen.dart';
import '../checklist_screen.dart';
import '../evacuation_guide_screen.dart';
import '../emergency_contacts_screen.dart';
import '../sos_setup_screen.dart';
import '../../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  // ─── Design tokens ────────────────────────────────────────────────────
  static const _bg = Color(0xFFF7F8FC);
  static const _surface = Color(0xFFFFFFFF);
  static const _surfaceSecondary = Color(0xFFF0F2F8);
  static const _accent = Color(0xFF2563EB);
  static const _accentLight = Color(0xFFEFF4FF);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _textTertiary = Color(0xFF94A3B8);
  static const _divider = Color(0xFFF1F5F9);
  static const _border = Color(0xFFE2E8F0);

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 700), vsync: this);
    _slideController = AnimationController(duration: const Duration(milliseconds: 650), vsync: this);

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(context, listen: false).fetchProfile();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    // LẮNG NGHE TRẠNG THÁI MẠNG
    final isOffline = context.watch<NetworkSyncProvider>().isOffline;

    return Scaffold(
      backgroundColor: _bg,
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          if (profileProvider.isLoading && profileProvider.profile == null) {
            return const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 1.5));
          }

          // ─── LỖI FETCH DATA HOẶC HẾT HẠN TOKEN ─────────────────────
          if (profileProvider.profile == null) {
            return Column(
              children: [
                if (isOffline) const SafeArea(bottom: false, child: OfflineBanner()),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72, height: 72,
                            decoration: BoxDecoration(color: _surfaceSecondary, borderRadius: BorderRadius.circular(20)),
                            child: const Icon(Icons.person_off_outlined, size: 32, color: _textTertiary),
                          ),
                          const SizedBox(height: 16),
                          const Text("Không thể tải thông tin cá nhân.\nPhiên đăng nhập có thể đã hết hạn.", textAlign: TextAlign.center, style: TextStyle(color: _textSecondary, fontSize: 14, height: 1.5)),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(child: _PrimaryButton(label: "Thử lại", onTap: () => profileProvider.fetchProfile())),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _showLogoutConfirm(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 13),
                                    decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFECDD3))),
                                    alignment: Alignment.center,
                                    child: const Text("Đăng xuất", style: TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.w700, fontSize: 14)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          final user = profileProvider.profile!;

          return Column(
            children: [
              // === ĐẶT BANNER Ở TRÊN CÙNG ĐỂ CỐ ĐỊNH KHI CUỘN ===
              if (isOffline) const SafeArea(bottom: false, child: OfflineBanner()),

              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // ── Hero header ───────────────────────────────────────
                        SliverToBoxAdapter(child: _buildHeader(user, isOffline)),

                        // ── Section: Tài khoản ────────────────────────────────
                        _buildSectionLabel("TÀI KHOẢN"),
                        SliverToBoxAdapter(
                          child: _buildCard([
                            _buildTile(
                              icon: Icons.person_outline_rounded,
                              title: "Cập nhật thông tin",
                              subtitle: "Thay đổi tên, số điện thoại, ảnh đại diện",
                              iconBg: const Color(0xFFEFF4FF),
                              iconColor: isOffline ? Colors.grey : const Color(0xFF2563EB), // Đổi màu xám nếu offline
                              onTap: isOffline
                                  ? () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng kết nối mạng để cập nhật thông tin."))); }
                                  : () => Navigator.push(context, _fadeRoute(EditProfileScreen(currentProfile: user))),
                            ),
                            _buildDivider(),
                            _buildTile(
                              icon: Icons.location_on_outlined,
                              title: "Vị trí quan tâm",
                              subtitle: "Quản lý nơi ở để nhận cảnh báo",
                              iconBg: const Color(0xFFFFF1F2),
                              iconColor: isOffline ? Colors.grey : const Color(0xFFE11D48),
                              onTap: isOffline
                                  ? () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tính năng quản lý vị trí yêu cầu kết nối mạng."))); }
                                  : () => Navigator.push(context, _fadeRoute(const SavedLocationsScreen())),
                            ),

                            _buildDivider(),
                            _buildTile(
                              icon: Icons.settings_rounded,
                              title: "Cài đặt hệ thống",
                              subtitle: "Tùy chỉnh thông báo, giao diện",
                              iconBg: const Color(0xFFF3E8FF), // Màu tím nhạt
                              iconColor: const Color(0xFF9333EA), // Màu tím
                              onTap: () => Navigator.push(
                                context,
                                _fadeRoute(const SettingsScreen()), // Gọi sang file mới
                              ),
                            ),
                          ]),
                        ),

                        // ── Section: Công cụ ứng phó ──────────────────────────
                        _buildSectionLabel("CÔNG CỤ ỨNG PHÓ"),
                        SliverToBoxAdapter(
                          child: _buildCard([
                            _buildTile(
                              icon: Icons.checklist_rounded,
                              title: "Checklist chuẩn bị ứng phó",
                              subtitle: "Danh sách vật dụng và việc cần làm khi có lũ",
                              iconBg: const Color(0xFFFFFBEB),
                              iconColor: const Color(0xFFD97706),
                              onTap: () => Navigator.push(context, _fadeRoute(const ChecklistScreen())),
                            ),
                            _buildDivider(),
                            _buildTile(
                              icon: Icons.directions_run_rounded,
                              title: "Hướng dẫn sơ tán an toàn",
                              subtitle: "Các bước di chuyển khi có bão lũ",
                              iconBg: const Color(0xFFF0FDF4),
                              iconColor: const Color(0xFF16A34A),
                              onTap: () => Navigator.push(context, _fadeRoute(const EvacuationGuideScreen())),
                            ),
                            _buildDivider(),
                            _buildTile(
                              icon: Icons.phone_in_talk_outlined,
                              title: "Danh bạ khẩn cấp",
                              subtitle: "Số cứu hộ và liên hệ người thân",
                              iconBg: const Color(0xFFFDF4FF),
                              iconColor: const Color(0xFF9333EA),
                              onTap: () => Navigator.push(context, _fadeRoute(const EmergencyContactsScreen())),
                            ),
                            _buildDivider(),
                            _buildTile(
                              icon: Icons.sos_rounded,
                              title: "Cài đặt SOS khẩn cấp",
                              subtitle: "Thiết lập lời nhắn mặc định khi gặp nạn",
                              iconBg: const Color(0xFFFDF4FF),
                              iconColor: Colors.red,
                              onTap: () => Navigator.push(context, _fadeRoute(const SosSetupScreen())),
                            ),
                          ]),
                        ),

                        // ── Logout ────────────────────────────────────────────
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                            child: _LogoutButton(onTap: () => _showLogoutConfirm(context)),
                          ),
                        ),

                        // ── Version label ─────────────────────────────────────
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20, bottom: 140),
                            child: Center(
                              child: Text("FWS • v1.0.0", style: TextStyle(fontSize: 11, color: _textTertiary, letterSpacing: 0.5)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────
  Widget _buildHeader(user, bool isOffline) {
    return Container(
      color: _surface,
      child: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7C3AED)]),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            top: !isOffline, // Nếu có Banner rồi thì không cần SafeArea nữa
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 6))],
                            ),
                            child: CircleAvatar(
                              radius: 36,
                              backgroundColor: _accentLight,
                              backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty ? NetworkImage(user.avatarUrl!) : null,
                              child: user.avatarUrl == null || user.avatarUrl!.isEmpty ? const Icon(Icons.person_rounded, size: 36, color: _accent) : null,
                            ),
                          ),
                          Positioned(
                            bottom: 2, right: 2,
                            child: Container(
                              width: 12, height: 12,
                              decoration: BoxDecoration(
                                color: isOffline ? Colors.orangeAccent : const Color(0xFF22C55E), // Đổi màu chấm xanh thành cam khi offline
                                shape: BoxShape.circle,
                                border: Border.all(color: _surface, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _textPrimary, letterSpacing: -0.4, height: 1.2)),
                            const SizedBox(height: 4),
                            Text(user.email, style: const TextStyle(fontSize: 13, color: _textSecondary), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Component phụ trợ khác ─────────────────────────────────────────────────────
  SliverToBoxAdapter _buildSectionLabel(String label) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 10),
        child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2.0, color: _textTertiary)),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Column(children: children)),
    );
  }

  Widget _buildTile({required IconData icon, required String title, String? subtitle, required Color iconBg, required Color iconColor, required VoidCallback onTap}) {
    return _AnimatedTile(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary, letterSpacing: -0.1)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: _textSecondary, height: 1.4)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: _textTertiary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, indent: 72, endIndent: 0, color: _divider);
  }

  Route _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 220),
    );
  }

  void _showLogoutConfirm(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 260),
      transitionBuilder: (ctx, anim, _, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (ctx, _, __) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: _border, width: 1), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 40, offset: const Offset(0, 16))]),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.logout_rounded, color: Color(0xFFE11D48), size: 26),
                ),
                const SizedBox(height: 18),
                const Text("Đăng xuất", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: _textPrimary, letterSpacing: -0.3)),
                const SizedBox(height: 8),
                const Text("Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?", textAlign: TextAlign.center, style: TextStyle(color: _textSecondary, fontSize: 13.5, height: 1.5)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(color: _surfaceSecondary, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
                          alignment: Alignment.center,
                          child: const Text("Hủy", style: TextStyle(color: _textSecondary, fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.pop(ctx);
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 1.5)),
                          );
                          try {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            await authProvider.logout();
                            if (context.mounted) {
                              Navigator.pop(context);
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                                    (Route<dynamic> route) => false,
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi đăng xuất: $e"), backgroundColor: Colors.redAccent));
                            }
                          }
                        },
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(color: const Color(0xFFE11D48), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: const Color(0xFFE11D48).withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))]),
                          alignment: Alignment.center,
                          child: const Text("Đăng xuất", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedTile extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _AnimatedTile({required this.child, required this.onTap});

  @override
  State<_AnimatedTile> createState() => _AnimatedTileState();
}

class _AnimatedTileState extends State<_AnimatedTile> with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _pressed ? const Color(0xFFF8FAFF) : Colors.transparent,
        child: widget.child,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
        decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 5))]),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
      ),
    );
  }
}

class _LogoutButton extends StatefulWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity, height: 52,
          decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFECDD3), width: 1)),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: Color(0xFFE11D48), size: 19),
              SizedBox(width: 9),
              Text("Đăng xuất", style: TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.w700, fontSize: 14.5, letterSpacing: 0.1)),
            ],
          ),
        ),
      ),
    );
  }
}