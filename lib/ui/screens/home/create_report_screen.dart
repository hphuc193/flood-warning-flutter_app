import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'map_picker_screen.dart';
import '../../../providers/report_provider.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen>
    with SingleTickerProviderStateMixin {
  final _descController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];

  double? _latitude;
  double? _longitude;
  bool _gettingLocation = true;

  // ── Thêm State cho Danh mục và Mức độ ─────────────────────────
  String? _selectedCategory;
  double _severityLevel = 1.0; // 1 đến 5

  final List<String> _incidentCategories = [
    "Nước ngập đường",
    "Nhà bị ngập",
    "Cầu đường sạt lở",
    "Cây đổ",
    "Mất điện",
    "Cần cứu trợ"
  ];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // ── Color tokens ──────────────────────────────────────────────
  static const Color _bg           = Color(0xFFF5F7FA);
  static const Color _surface      = Color(0xFFFFFFFF);
  static const Color _primary      = Color(0xFF2563EB);
  static const Color _primaryLight = Color(0xFFEFF6FF);
  static const Color _accent       = Color(0xFFEF4444);
  static const Color _textPrimary  = Color(0xFF111827);
  static const Color _textSecondary= Color(0xFF6B7280);
  static const Color _border       = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _animController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ── Logic (unchanged) ─────────────────────────────────────────
  Future<void> _getCurrentLocation() async {
    setState(() => _gettingLocation = true);
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) { setState(() => _gettingLocation = false); return; }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _gettingLocation = false); return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _gettingLocation = false); return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _latitude  = position.latitude;
      _longitude = position.longitude;
      _gettingLocation = false;
    });
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerScreen()),
    );
    if (result != null && result is List<double>) {
      setState(() {
        _latitude  = result[0];
        _longitude = result[1];
        _gettingLocation = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) setState(() => _selectedImages.addAll(images));
  }

  // Helper chuyển đổi màu theo mức độ nghiêm trọng
  Color _getSeverityColor(double level) {
    if (level == 1) return Colors.green;
    if (level == 2) return Colors.lightBlue;
    if (level == 3) return Colors.orangeAccent;
    if (level == 4) return Colors.deepOrange;
    return Colors.red;
  }

  // Helper chuyển đổi text theo mức độ nghiêm trọng
  String _getSeverityLabel(double level) {
    if (level == 1) return "Thấp";
    if (level == 2) return "Vừa phải";
    if (level == 3) return "Nghiêm trọng";
    if (level == 4) return "Rất nghiêm trọng";
    return "Khẩn cấp";
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel("📍 Vị trí sự cố"),
              const SizedBox(height: 10),
              _buildLocationCard(),
              const SizedBox(height: 24),

              // ── BỔ SUNG: CHỌN DANH MỤC SỰ CỐ ──────────
              _sectionLabel("Loại sự cố"),
              const SizedBox(height: 10),
              _buildCategorySelection(),
              const SizedBox(height: 24),

              // ── BỔ SUNG: KÉO MỨC ĐỘ NGHIÊM TRỌNG ──────────
              _sectionLabel("Mức độ nghiêm trọng"),
              const SizedBox(height: 10),
              _buildSeveritySlider(),
              const SizedBox(height: 24),

              _sectionLabel("Mô tả tình trạng"),
              const SizedBox(height: 10),
              _buildDescriptionField(),
              const SizedBox(height: 24),

              _sectionLabel("Hình ảnh hiện trường"),
              const SizedBox(height: 10),
              _buildImageSection(),
              const SizedBox(height: 36),

              _buildSubmitButton(reportProvider),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: _surface,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _textPrimary),
      onPressed: () => Navigator.pop(context),
    ),
    title: const Text(
      "Gửi báo cáo",
      style: TextStyle(
        color: _textPrimary, fontSize: 18,
        fontWeight: FontWeight.w700, letterSpacing: -0.3,
      ),
    ),
    centerTitle: true,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: _border),
    ),
  );

  // ── Section label ──────────────────────────────────────────────
  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w600,
      color: _textSecondary, letterSpacing: 0.2,
    ),
  );

  // ── Card container helper ──────────────────────────────────────
  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );

  // ── UI MỚI: Danh mục sự cố ────────────────────────────────────
  Widget _buildCategorySelection() => _card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 10,
        runSpacing: 12,
        children: _incidentCategories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return ChoiceChip(
            label: Text(cat),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (selected) {
              setState(() {
                _selectedCategory = selected ? cat : null;
              });
            },
            backgroundColor: _bg,
            selectedColor: _primaryLight,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? _primary : _textSecondary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: isSelected ? _primary : _border,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
          );
        }).toList(),
      ),
    ),
  );

  // ── UI MỚI: Kéo thanh mức độ nghiêm trọng ──────────────────────
  Widget _buildSeveritySlider() {
    final activeColor = _getSeverityColor(_severityLevel);

    return _card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_rounded, color: activeColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _getSeverityLabel(_severityLevel),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: activeColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  "${_severityLevel.toInt()}/5",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: activeColor,
                inactiveTrackColor: _border,
                thumbColor: activeColor,
                overlayColor: activeColor.withOpacity(0.2),
                trackHeight: 6,
              ),
              child: Slider(
                value: _severityLevel,
                min: 1,
                max: 5,
                divisions: 4,
                onChanged: (val) {
                  setState(() {
                    _severityLevel = val;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text("Nhẹ", style: TextStyle(fontSize: 11, color: _textSecondary)),
                  Text("Nặng", style: TextStyle(fontSize: 11, color: _textSecondary)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // ── Location Card ──────────────────────────────────────────────
  Widget _buildLocationCard() => _card(
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on_rounded, color: _primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _gettingLocation
                    ? const Row(children: [
                  SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
                  ),
                  SizedBox(width: 10),
                  Text("Đang xác định vị trí...",
                      style: TextStyle(color: _textSecondary, fontSize: 14)),
                ])
                    : _latitude != null
                    ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Tọa độ hiện tại",
                      style: TextStyle(
                        fontSize: 11, color: _textSecondary,
                        fontWeight: FontWeight.w500,
                      )),
                  const SizedBox(height: 3),
                  Text(
                    "${_latitude!.toStringAsFixed(5)}°N,  ${_longitude!.toStringAsFixed(5)}°E",
                    style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14,
                      color: _textPrimary, letterSpacing: -0.2,
                    ),
                  ),
                ])
                    : const Text(
                  "Chưa có vị trí. Bật GPS hoặc chọn trên bản đồ.",
                  style: TextStyle(color: _textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        Container(height: 1, color: _border),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(child: _locBtn(icon: Icons.my_location_rounded,  label: "GPS hiện tại",  onTap: _getCurrentLocation, filled: false)),
            const SizedBox(width: 10),
            Expanded(child: _locBtn(icon: Icons.map_rounded,           label: "Chọn bản đồ",  onTap: _openMapPicker,      filled: true)),
          ]),
        ),
      ],
    ),
  );

  Widget _locBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool filled,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: filled ? _primary : _primaryLight,
            borderRadius: BorderRadius.circular(12),
            border: filled ? null : Border.all(color: _primary.withOpacity(0.3)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16, color: filled ? Colors.white : _primary),
            const SizedBox(width: 7),
            Text(label,
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: filled ? Colors.white : _primary,
              ),
            ),
          ]),
        ),
      );

  // ── Description Field ──────────────────────────────────────────
  Widget _buildDescriptionField() => _card(
    child: TextField(
      controller: _descController,
      maxLines: 4,
      style: const TextStyle(fontSize: 14, color: _textPrimary, height: 1.55),
      decoration: InputDecoration(
        hintText: "Nhập thêm thông tin chi tiết (nếu có)...",
        hintStyle: const TextStyle(color: _textSecondary, fontSize: 13, height: 1.5),
        contentPadding: const EdgeInsets.all(16),
        border: InputBorder.none,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );

  // ── Image Section ──────────────────────────────────────────────
  Widget _buildImageSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _primary.withOpacity(0.35), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(children: [
            Container(
              width: 46, height: 46,
              decoration: const BoxDecoration(color: _primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.add_photo_alternate_rounded, color: _primary, size: 22),
            ),
            const SizedBox(height: 8),
            const Text("Thêm hình ảnh hiện trường",
                style: TextStyle(color: _primary, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 2),
            const Text("Chụp ảnh hoặc chọn từ thư viện",
                style: TextStyle(color: _textSecondary, fontSize: 12)),
          ]),
        ),
      ),
      if (_selectedImages.isNotEmpty) ...[
        const SizedBox(height: 14),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length,
            itemBuilder: (ctx, i) => Stack(children: [
              Container(
                margin: const EdgeInsets.only(right: 10),
                width: 100, height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                  image: DecorationImage(
                    image: FileImage(File(_selectedImages[i].path)),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
              ),
              Positioned(
                right: 6, top: 4,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedImages.removeAt(i)),
                  child: Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 6),
        Text("${_selectedImages.length} ảnh đã chọn",
            style: const TextStyle(fontSize: 12, color: _textSecondary)),
      ],
    ],
  );

  // ── Submit Button ──────────────────────────────────────────────
  Widget _buildSubmitButton(ReportProvider reportProvider) {
    final bool disabled = reportProvider.isLoading || _latitude == null;
    return GestureDetector(
      onTap: disabled ? null : () async {
        // UI Validation
        if (_selectedCategory == null) {
          _snack("Vui lòng chọn loại sự cố"); return;
        }
        if (_descController.text.isEmpty) {
          _snack("Vui lòng nhập mô tả tình trạng"); return;
        }

        // GỌI HÀM VỚI ĐẦY ĐỦ THAM SỐ MỚI
        bool success = await reportProvider.createReport(
          _latitude!,
          _longitude!,
          _descController.text,
          _selectedCategory!,         // Truyền danh mục đã chọn
          _severityLevel.toInt(),     // Ép slider (double) sang int (1-5)
          _selectedImages.map((e) => e.path).toList(),
          context,
        );

        if (success && context.mounted) {
          _snack("Gửi báo cáo thành công! 🎉");
          Navigator.pop(context);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity, height: 56,
        decoration: BoxDecoration(
          gradient: disabled ? null : const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          color: disabled ? _border : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: disabled ? [] : [
            BoxShadow(
              color: const Color(0xFFEF4444).withOpacity(0.35),
              blurRadius: 16, offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: reportProvider.isLoading
              ? const SizedBox(
            width: 22, height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
          )
              : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.send_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text("GỬI BÁO CÁO NGAY",
              style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800,
                fontSize: 15, letterSpacing: 0.5,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ),
  );
}