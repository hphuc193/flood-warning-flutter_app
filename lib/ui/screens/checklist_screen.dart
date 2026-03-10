import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/checklist_provider.dart';
import 'profile/profile_screen.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChecklistProvider>(context, listen: false).initData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // KHI USER THOÁT MÀN HÌNH -> GỌI HÀM SYNC DATA LÊN SERVER
        Provider.of<ChecklistProvider>(context, listen: false).syncDataWithServer();
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text("Chuẩn bị ứng phó"),
          centerTitle: true, // Căn giữa tiêu đề cho đẹp
          iconTheme: const IconThemeData(color: Colors.white), // Đổi màu nút Back thành trắng
          actions: [
            // Thêm nút mở Profile ở góc phải
            IconButton(
              icon: const Icon(Icons.person_outline, size: 28),
              tooltip: 'Trang cá nhân',
              onPressed: () {
                // Đẩy ProfileScreen lên 스택 (Stack) điều hướng
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: 8), // Tạo một chút khoảng cách với lề phải
          ],
        ),
        body: Consumer<ChecklistProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.categories.isEmpty) {
              return const Center(child: Text("Không có dữ liệu checklist."));
            }

            return Column(
              children: [
                // 1. PROGRESS BAR NỔI BẬT
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Tiến độ chuẩn bị", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("${(provider.progress * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: provider.progress,
                          minHeight: 12,
                          backgroundColor: Colors.grey[300],
                          color: provider.progress == 1.0 ? Colors.green : Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. DANH SÁCH CHECKLIST THEO NHÓM
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: provider.categories.length,
                    itemBuilder: (context, index) {
                      final category = provider.categories[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Nhóm
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              ),
                              child: Text(
                                category.categoryName,
                                // Đã bỏ chữ 'const' ở đầu và sửa thành Colors.blue[800]
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue[800]),
                              ),
                            ),
                            // Danh sách Item trong nhóm
                            ...category.items.map((item) {
                              bool isCompleted = provider.completedItemIds.contains(item.id);
                              return CheckboxListTile(
                                activeColor: Colors.green,
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: TextStyle(
                                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                                          color: isCompleted ? Colors.grey : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    if (item.isImportant)
                                      const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                                  ],
                                ),
                                value: isCompleted,
                                onChanged: (bool? value) {
                                  if (value != null) {
                                    provider.toggleItem(item.id, value);
                                  }
                                },
                              );
                            }).toList(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}