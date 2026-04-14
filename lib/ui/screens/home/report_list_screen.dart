import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/report_provider.dart';
import '../../widgets/report_detail_modal.dart';
import '../alert/alert_detail_screen.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  static const _bg = Color(0xFFF7F8FC);
  static const _surface = Color(0xFFFFFFFF);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _textTertiary = Color(0xFF94A3B8);

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // --- CÁC BIẾN BỘ LỌC MỚI ---
  String _selectedStatus = '';
  String _selectedCategory = '';
  String _selectedSeverity = '';
  String _selectedTimeRange = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        context.read<ReportProvider>().loadMoreReports();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onRefresh();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _onRefresh();
    });
  }

  // --- TRUYỀN THÊM THAM SỐ MỚI VÀO PROVIDER ---
  Future<void> _onRefresh() async {
    await context.read<ReportProvider>().fetchReports(
      reset: true,
      search: _searchController.text,
      status: _selectedStatus,
      category: _selectedCategory,
      severity: _selectedSeverity,
      timeRange: _selectedTimeRange,
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    final reportProvider = Provider.of<ReportProvider>(context);
    final reports = reportProvider.reports;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(context, reportProvider.totalItems),
          _buildSearchBar(),
          _buildAdvancedFilters(), // Thay thế bằng bộ lọc nâng cao
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: const Color(0xFF2563EB),
              child: reports.isEmpty && !reportProvider.isLoading
                  ? _buildEmptyState()
                  : ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 150),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: reports.length + (reportProvider.isFetchingMore ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, index) {
                  if (index == reports.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }

                  final report = reports[index];
                  final formattedDate = DateFormat('HH:mm · dd/MM/yyyy').format(report.createdAt);
                  return _ReportCard(
                    report: report,
                    formattedDate: formattedDate,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => ReportDetailModal(report: report),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Báo cáo cộng đồng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textPrimary, letterSpacing: -0.4)),
                        Text("Vuốt xuống để cập nhật", style: TextStyle(fontSize: 12, color: _textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2563EB)),
                    onPressed: _onRefresh,
                    tooltip: "Làm mới",
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertDetailScreen()));
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                      ),
                      child: const Icon(Icons.notification_important_rounded, color: Colors.redAccent, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: _surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: const InputDecoration(
            hintText: "Tìm kiếm khu vực, mô tả...",
            hintStyle: TextStyle(color: _textTertiary, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: _textSecondary),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // --- BỘ LỌC NÂNG CAO ---
  Widget _buildAdvancedFilters() {
    return Container(
      color: _surface,
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _buildDropdownFilter(
              value: _selectedStatus,
              hint: 'Trạng thái',
              items: const [
                DropdownMenuItem(value: '', child: Text('Tất cả trạng thái')),
                DropdownMenuItem(value: 'verified', child: Text('Đã xác minh')),
                DropdownMenuItem(value: 'pending', child: Text('Chờ duyệt')),
                DropdownMenuItem(value: 'rejected', child: Text('Từ chối')),
              ],
              onChanged: (val) { setState(() => _selectedStatus = val!); _onRefresh(); },
            ),
            const SizedBox(width: 8),
            _buildDropdownFilter(
              value: _selectedTimeRange,
              hint: 'Thời gian',
              items: const [
                DropdownMenuItem(value: '', child: Text('Mọi lúc')),
                DropdownMenuItem(value: '24h', child: Text('24 giờ qua')),
                DropdownMenuItem(value: '3d', child: Text('3 ngày qua')),
                DropdownMenuItem(value: '7d', child: Text('7 ngày qua')),
                DropdownMenuItem(value: '30d', child: Text('30 ngày qua')),
              ],
              onChanged: (val) { setState(() => _selectedTimeRange = val!); _onRefresh(); },
            ),
            const SizedBox(width: 8),
            _buildDropdownFilter(
              value: _selectedSeverity,
              hint: 'Mức độ',
              items: const [
                DropdownMenuItem(value: '', child: Text('Mọi mức độ')),
                DropdownMenuItem(value: '1', child: Text('Cấp 1 - Nhẹ')),
                DropdownMenuItem(value: '2,3', child: Text('Cấp 2, 3 - Vừa')),
                DropdownMenuItem(value: '4,5', child: Text('Cấp 4, 5 - Nghiêm trọng')),
              ],
              onChanged: (val) { setState(() => _selectedSeverity = val!); _onRefresh(); },
            ),
            const SizedBox(width: 8),
            _buildDropdownFilter(
              value: _selectedCategory,
              hint: 'Loại sự cố',
              items: const [
                DropdownMenuItem(value: '', child: Text('Tất cả sự cố')),
                DropdownMenuItem(value: 'Nước ngập đường', child: Text('Nước ngập đường')),
                DropdownMenuItem(value: 'Nhà bị ngập', child: Text('Nhà bị ngập')),
                DropdownMenuItem(value: 'Cây đổ', child: Text('Cây đổ')),
                DropdownMenuItem(value: 'Mất điện', child: Text('Mất điện')),
              ],
              onChanged: (val) { setState(() => _selectedCategory = val!); _onRefresh(); },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownFilter({required String value, required String hint, required List<DropdownMenuItem<String>> items, required Function(String?) onChanged}) {
    final isSelected = value.isNotEmpty;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: isSelected ? const Color(0xFF2563EB) : _textSecondary),
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? const Color(0xFF2563EB) : _textSecondary,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: const Color(0xFFEFF4FF), borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.search_off_rounded, color: Color(0xFF2563EB), size: 30),
          ),
          const SizedBox(height: 16),
          const Text("Không tìm thấy kết quả", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textPrimary)),
          const SizedBox(height: 6),
          const Text("Thử thay đổi từ khóa hoặc bộ lọc\nđể tìm lại nhé.", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: _textTertiary, height: 1.5)),
        ],
      ),
    );
  }
}

class _ReportCard extends StatefulWidget {
  final dynamic report;
  final String formattedDate;
  final VoidCallback onTap;

  const _ReportCard({required this.report, required this.formattedDate, required this.onTap});

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _pressed = false;

  static const _surface = Color(0xFFFFFFFF);
  static const _border = Color(0xFFE2E8F0);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _textTertiary = Color(0xFF94A3B8);

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

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final statusConfig = _getStatusConfig(report.status);
    final sevColor = _getSeverityColor(report.severity); // Thuộc tính mới

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: _pressed ? const Color(0xFFF8FAFF) : _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 78, height: 78,
                      child: report.images.isNotEmpty
                          ? Image.network(report.images[0], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF1F5F9), child: const Icon(Icons.broken_image_outlined, color: Color(0xFF94A3B8), size: 24)))
                          : Container(color: const Color(0xFFF1F5F9), child: const Icon(Icons.image_outlined, color: Color(0xFF94A3B8), size: 24)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: Text(report.reporterName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _textPrimary, letterSpacing: -0.1), overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: statusConfig['bg'], borderRadius: BorderRadius.circular(20), border: Border.all(color: statusConfig['border'], width: 1)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(width: 5, height: 5, decoration: BoxDecoration(color: statusConfig['color'], shape: BoxShape.circle)),
                                  const SizedBox(width: 4),
                                  Text(statusConfig['label'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusConfig['color'])),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(report.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: _textSecondary, height: 1.45)),
                        const SizedBox(height: 8),

                        // --- ROW MỚI HIỂN THỊ LOẠI SỰ CỐ & MỨC ĐỘ ---
                        Row(
                          children: [
                            if (report.category != null && report.category.toString().isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                                child: Text(report.category, style: const TextStyle(fontSize: 10, color: _textSecondary, fontWeight: FontWeight.w600)),
                              ),
                            if (report.category != null) const SizedBox(width: 6),
                            if (report.severity != null)
                              Row(
                                children: [
                                  Icon(Icons.warning_rounded, size: 12, color: sevColor),
                                  const SizedBox(width: 2),
                                  Text("Cấp ${report.severity}", style: TextStyle(fontSize: 10, color: sevColor, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            const Spacer(),
                            const Text("Xem chi tiết", style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
                            const Icon(Icons.chevron_right_rounded, size: 13, color: Color(0xFF2563EB)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(height: 1, color: _border),
              ),
              Row(
                children: [
                  _buildVoteButton(
                    context: context,
                    reportId: report.id,
                    icon: report.currentUserVote == 'upvote' ? Icons.thumb_up_alt_rounded : Icons.thumb_up_off_alt_rounded,
                    count: report.upvotes,
                    color: report.currentUserVote == 'upvote' ? const Color(0xFF2563EB) : _textSecondary,
                    type: 'upvote',
                  ),
                  const SizedBox(width: 24),
                  _buildVoteButton(
                    context: context,
                    reportId: report.id,
                    icon: report.currentUserVote == 'downvote' ? Icons.thumb_down_alt_rounded : Icons.thumb_down_off_alt_rounded,
                    count: report.downvotes,
                    color: report.currentUserVote == 'downvote' ? const Color(0xFFE11D48) : _textSecondary,
                    type: 'downvote',
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoteButton({required BuildContext context, required int reportId, required IconData icon, required int count, required Color color, required String type}) {
    return GestureDetector(
      onTap: () {
        Provider.of<ReportProvider>(context, listen: false).voteReport(reportId, type);
      },
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(count.toString(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}