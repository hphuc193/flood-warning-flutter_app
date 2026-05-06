import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../../providers/network_sync_provider.dart';
import '../../../providers/setting_provider.dart';
import '../../widgets/offline_banner.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _bg = Color(0xFFF7F8FC);
  static const _surface = Color(0xFFFFFFFF);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);
  static const _accent = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SettingProvider>(context, listen: false).fetchSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = context.watch<NetworkSyncProvider>().isOffline;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _textPrimary),
        title: const Text("Cài đặt hệ thống", style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      ),
      body: Column(
        children: [
          // Banner cảnh báo Mất mạng
          if (isOffline) const OfflineBanner(),

          Expanded(
            child: Consumer<SettingProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.settings == null) {
                  return const Center(child: CircularProgressIndicator(color: _accent));
                }

                if (provider.settings == null) {
                  return const Center(child: Text("Không thể tải cài đặt."));
                }

                final settings = provider.settings!;

                return ListView(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildSectionTitle("THÔNG BÁO VÀ CẢNH BÁO"),
                    const SizedBox(height: 10),
                    _buildSettingsCard([
                      _buildSwitchTile(
                        icon: CupertinoIcons.bell_solid,
                        iconColor: Colors.blue,
                        title: "Thông báo đẩy (Push)",
                        subtitle: "Nhận cảnh báo qua ứng dụng",
                        value: settings.notiPush,
                        isDisabled: isOffline,
                        onChanged: (val) => provider.updateSetting(notiPush: val),
                      ),
                      _buildDivider(),
                      _buildSwitchTile(
                        icon: CupertinoIcons.chat_bubble_text_fill,
                        iconColor: Colors.green,
                        title: "Cảnh báo qua SMS",
                        subtitle: "Sử dụng khi không có mạng 4G",
                        value: settings.notiSms,
                        isDisabled: isOffline,
                        onChanged: (val) => provider.updateSetting(notiSms: val),
                      ),
                      _buildDivider(),
                      _buildSwitchTile(
                        icon: CupertinoIcons.mail_solid,
                        iconColor: Colors.orange,
                        title: "Nhận email tổng hợp",
                        subtitle: "Báo cáo thời tiết gửi qua hòm thư",
                        value: settings.notiEmail,
                        isDisabled: isOffline,
                        onChanged: (val) => provider.updateSetting(notiEmail: val),
                      ),
                    ]),

                    const SizedBox(height: 24),
                    _buildSectionTitle("TIỆN ÍCH"),
                    const SizedBox(height: 10),
                    _buildSettingsCard([
                      _buildSwitchTile(
                        icon: CupertinoIcons.cloud_sun_fill,
                        iconColor: Colors.deepPurple,
                        title: "Bản tin thời tiết hằng ngày",
                        subtitle: "Nhận thông báo vào 6h00 sáng",
                        value: settings.dailyWeatherNoti,
                        isDisabled: isOffline,
                        onChanged: (val) => provider.updateSetting(dailyWeatherNoti: val),
                      ),
                    ]),

                    // Giao diện tĩnh (Chưa xử lý chuyển Theme ngay, có thể nâng cấp sau)
                    const SizedBox(height: 24),
                    _buildSectionTitle("GIAO DIỆN"),
                    const SizedBox(height: 10),
                    _buildSettingsCard([
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: const Icon(CupertinoIcons.moon_stars_fill, color: Colors.black87),
                        title: const Text("Chủ đề (Theme)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        subtitle: Text(settings.theme == 'system' ? "Theo hệ thống" : (settings.theme == 'dark' ? "Chế độ tối" : "Chế độ sáng"), style: const TextStyle(fontSize: 13)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: _textSecondary),
                        onTap: isOffline
                            ? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tính năng bị khóa khi ngoại tuyến")))
                            : () {
                          // Có thể thêm Popup menu để chọn theme ở đây sau
                        },
                      )
                    ]),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _textSecondary, letterSpacing: 1.0)),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Column(children: children)),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, indent: 60, endIndent: 0, color: Color(0xFFF1F5F9));
  }

  Widget _buildSwitchTile({required IconData icon, required Color iconColor, required String title, required String subtitle, required bool value, required bool isDisabled, required Function(bool) onChanged}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: isDisabled ? Colors.grey.shade100 : iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: isDisabled ? Colors.grey : iconColor, size: 22),
      ),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDisabled ? Colors.grey : _textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: _textSecondary)),
      trailing: CupertinoSwitch(
        activeColor: _accent,
        value: value,
        onChanged: isDisabled ? null : onChanged, // Tự động xám và khóa công tắc nếu đang Offline
      ),
    );
  }
}