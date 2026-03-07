import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/flood_report_model.dart';

class ReportDetailModal extends StatelessWidget {
  final FloodReport report;

  const ReportDetailModal({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    // Format ngày giờ: Ví dụ 14:30 - 07/02/2026
    final formattedDate = DateFormat('HH:mm - dd/MM/yyyy').format(report.createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      // Chiều cao linh hoạt tùy nội dung
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Avatar (giả) + Tên + Thời gian
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(report.reporterName[0].toUpperCase()),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.reporterName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    formattedDate,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Text("ĐANG NGẬP", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 12),

          // 2. Nội dung mô tả
          Text(
            report.description,
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 12),

          // 3. Danh sách ảnh (Horizontal Scroll)
          if (report.images.isNotEmpty)
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: report.images.length,
                itemBuilder: (ctx, index) {
                  return GestureDetector(
                    onTap: () {
                      // Có thể mở ảnh full screen ở đây (tính năng nâng cao)
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(report.images[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text("Không có hình ảnh đính kèm", style: TextStyle(color: Colors.grey))),
            ),

          const SizedBox(height: 20),

          // 4. Nút đóng
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Đóng"),
            ),
          )
        ],
      ),
    );
  }
}