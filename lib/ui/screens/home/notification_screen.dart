import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications(refresh: true);
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // === HÀM HỖ TRỢ LẤY MÀU SẮC DỰA VÀO TYPE ===
  Color _getNotifColor(String type, bool isRead) {
    if (isRead) return Colors.grey; // Nếu đã đọc thì auto xám
    switch (type.toUpperCase()) {
      case 'REPORT': return Colors.orange;
      case 'SOS': return Colors.redAccent;
      case 'WEATHER': return Colors.blueAccent;
      default: return Colors.blueAccent;
    }
  }

  // === HÀM HỖ TRỢ LẤY ICON DỰA VÀO TYPE ===
  IconData _getNotifIcon(String type) {
    switch (type.toUpperCase()) {
      case 'REPORT': return Icons.warning_rounded;
      case 'SOS': return Icons.sos_rounded;
      case 'WEATHER': return Icons.cloud_circle_rounded;
      default: return Icons.notifications_active_rounded;
    }
  }

  // POPUP CHI TIẾT
  void _showNotificationDetail(BuildContext context, dynamic notif) {
    final themeColor = _getNotifColor(notif.type, false);

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return Container(
            padding: const EdgeInsets.all(24.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: themeColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                        child: Icon(_getNotifIcon(notif.type), color: themeColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(notif.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('HH:mm - dd/MM/yyyy').format(notif.createdAt),
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200)
                    ),
                    child: Text(
                      notif.content,
                      style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF334155)),
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Đóng", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      )
                  )
                ],
              ),
            ),
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        title: const Text("Thông báo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () {
              Provider.of<NotificationProvider>(context, listen: false).markAllAsRead();
            },
            child: const Text("Đọc tất cả", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600)),
          )
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Bạn chưa có thông báo nào", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchNotifications(refresh: true),
            child: ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: provider.notifications.length + (provider.hasMore ? 1 : 0),
              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
              itemBuilder: (context, index) {
                if (index == provider.notifications.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }

                final notif = provider.notifications[index];

                // Lấy màu và icon tương ứng
                final themeColor = _getNotifColor(notif.type, notif.isRead);
                final iconData = _getNotifIcon(notif.type);

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  tileColor: notif.isRead ? Colors.transparent : themeColor.withValues(alpha: 0.05),
                  leading: CircleAvatar(
                    backgroundColor: notif.isRead ? Colors.grey.shade200 : themeColor.withValues(alpha: 0.15),
                    child: Icon(iconData, color: themeColor),
                  ),
                  title: Text(
                    notif.title,
                    style: TextStyle(fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        notif.content,
                        style: const TextStyle(color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('HH:mm - dd/MM/yyyy').format(notif.createdAt),
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                  onTap: () {
                    provider.markAsRead(notif.id);
                    _showNotificationDetail(context, notif);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}