import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/flood_report_model.dart';
import '../../../providers/report_provider.dart';

class ReportDetailModal extends StatelessWidget {
  final FloodReport report;

  const ReportDetailModal({super.key, required this.report});

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'verified': return {'label': 'Đã xác minh', 'color': const Color(0xFF059669), 'bg': const Color(0xFFD1FAE5), 'border': const Color(0xFFA7F3D0)};
      case 'rejected': return {'label': 'Bị từ chối', 'color': const Color(0xFFDC2626), 'bg': const Color(0xFFFEE2E2), 'border': const Color(0xFFFECACA)};
      case 'pending': default: return {'label': 'Chờ duyệt', 'color': const Color(0xFFD97706), 'bg': const Color(0xFFFEF3C7), 'border': const Color(0xFFFDE68A)};
    }
  }

  // --- TRỢ THỦ LẤY MÀU MỨC ĐỘ ---
  Color _getSeverityColor(int? level) {
    if (level == null) return Colors.grey;
    if (level == 1) return Colors.green;
    if (level == 2) return Colors.lightBlue;
    if (level == 3) return Colors.orangeAccent;
    if (level == 4) return Colors.deepOrange;
    return Colors.red;
  }

  String _getSeverityLabel(int? level) {
    if (level == 1) return "Thấp";
    if (level == 2) return "Vừa phải";
    if (level == 3) return "Nghiêm trọng";
    if (level == 4) return "Rất nghiêm trọng";
    if (level == 5) return "Khẩn cấp";
    return "Chưa phân loại";
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, provider, child) {
        final currentReport = provider.reports.firstWhere(
              (r) => r.id == report.id,
          orElse: () => report,
        );

        final formattedDate = DateFormat('HH:mm - dd/MM/yyyy').format(currentReport.createdAt);
        final statusConfig = _getStatusConfig(currentReport.status);
        final sevColor = _getSeverityColor(currentReport.severity);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(currentReport.reporterName.isNotEmpty ? currentReport.reporterName[0].toUpperCase() : '?'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentReport.reporterName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        Text(formattedDate, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: statusConfig['bg'], borderRadius: BorderRadius.circular(12), border: Border.all(color: statusConfig['border'])),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 6, height: 6, decoration: BoxDecoration(color: statusConfig['color'], shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text(statusConfig['label'], style: TextStyle(color: statusConfig['color'], fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12),

              // 2. Nội dung mô tả
              Text(currentReport.description, style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 12),

              // --- BỔ SUNG: HIỂN THỊ LOẠI SỰ CỐ VÀ MỨC ĐỘ ---
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (currentReport.category != null && currentReport.category!.isNotEmpty)
                    Chip(
                      label: Text(currentReport.category!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      backgroundColor: Colors.grey.shade100,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: EdgeInsets.zero,
                    ),
                  if (currentReport.severity != null)
                    Chip(
                      avatar: Icon(Icons.warning_rounded, color: sevColor, size: 16),
                      label: Text("Cấp ${currentReport.severity} - ${_getSeverityLabel(currentReport.severity)}", style: TextStyle(fontSize: 12, color: sevColor, fontWeight: FontWeight.w700)),
                      backgroundColor: sevColor.withOpacity(0.1),
                      side: BorderSide(color: sevColor.withOpacity(0.3)),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // ---------------------------------------------

              // 3. Danh sách ảnh
              if (currentReport.images.isNotEmpty)
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: currentReport.images.length,
                    itemBuilder: (ctx, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(image: NetworkImage(currentReport.images[index]), fit: BoxFit.cover),
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text("Không có hình ảnh đính kèm", style: TextStyle(color: Colors.grey))),
                ),

              const SizedBox(height: 16),

              // 4. Thanh Upvote / Downvote
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  children: [
                    _buildVoteButton(
                      context: context, reportId: currentReport.id,
                      icon: currentReport.currentUserVote == 'upvote' ? Icons.thumb_up_alt_rounded : Icons.thumb_up_off_alt_rounded,
                      count: currentReport.upvotes,
                      color: currentReport.currentUserVote == 'upvote' ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                      type: 'upvote',
                    ),
                    const SizedBox(width: 24),
                    _buildVoteButton(
                      context: context, reportId: currentReport.id,
                      icon: currentReport.currentUserVote == 'downvote' ? Icons.thumb_down_alt_rounded : Icons.thumb_down_off_alt_rounded,
                      count: currentReport.downvotes,
                      color: currentReport.currentUserVote == 'downvote' ? const Color(0xFFE11D48) : const Color(0xFF64748B),
                      type: 'downvote',
                    ),
                  ],
                ),
              ),

              // 5. Nút đóng
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade50, foregroundColor: Colors.blue.shade700,
                    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Đóng", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildVoteButton({required BuildContext context, required int reportId, required IconData icon, required int count, required Color color, required String type}) {
    return GestureDetector(
      onTap: () {
        Provider.of<ReportProvider>(context, listen: false).voteReport(reportId, type);
      },
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
          Text(count.toString(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}