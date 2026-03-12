import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../../../providers/report_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/weather_provider.dart';
import '../../widgets/report_detail_modal.dart';
import '../../widgets/weather_info_card.dart';
import '../auth/login_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  // --- GPS LOCATION ---
  LatLng? _userLocation;

  // --- MAP STYLE LIST ---
  final List<Map<String, dynamic>> _mapStyles = [
    {'name': 'Tiêu chuẩn', 'subtitle': 'OpenStreetMap', 'url': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', 'icon': CupertinoIcons.map, 'color': const Color(0xFF007AFF)},
    {'name': 'Nhân đạo', 'subtitle': 'Cứu trợ thiên tai', 'url': 'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png', 'icon': CupertinoIcons.heart_fill, 'color': const Color(0xFFFF3B30)},
    {'name': 'Địa hình', 'subtitle': 'OpenTopoMap', 'url': 'https://tile.opentopomap.org/{z}/{x}/{y}.png', 'icon': CupertinoIcons.waveform, 'color': const Color(0xFF34C759)},
    {'name': 'Vệ tinh', 'subtitle': 'Esri World Imagery', 'url': 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', 'icon': CupertinoIcons.globe, 'color': const Color(0xFF5856D6)},
    {'name': 'Giao thông', 'subtitle': 'CartoCDN Voyager', 'url': 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png', 'icon': CupertinoIcons.car_fill, 'color': const Color(0xFFFF9500)},
  ];

  String _currentMapUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  String _currentMapName = 'Tiêu chuẩn';

  // --- SEARCH ---
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<dynamic> _suggestions = [];
  bool _isLoadingSuggestions = false;
  CancelToken? _cancelToken;

  bool _showLegend = false;
  late AnimationController _legendAnimController;
  late Animation<double> _legendAnim;

  @override
  void initState() {
    super.initState();
    _legendAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _legendAnim = CurvedAnimation(parent: _legendAnimController, curve: Curves.easeOutCubic);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _moveToCurrentLocation();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _cancelToken?.cancel();
    _legendAnimController.dispose();
    super.dispose();
  }

  // ==========================================
  // HÀM TÌM KIẾM
  // ==========================================
  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoadingSuggestions = false;
        });
      }
      return;
    }

    _cancelToken?.cancel("Cancelled due to new request");
    _cancelToken = CancelToken();

    if (mounted) setState(() => _isLoadingSuggestions = true);

    try {
      final url = "https://photon.komoot.io/api/?q=$query&limit=5&lang=en";

      final response = await Dio().get(
        url,
        cancelToken: _cancelToken,
        options: Options(headers: {
          'User-Agent': 'FloodWarningMobileApp/1.0',
          'Accept': 'application/json'
        }),
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _suggestions = response.data['features'] as List;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        // Ignored
      } else {
        print("❌ Lỗi tìm kiếm Photon: $e");
        if (mounted) setState(() => _isLoadingSuggestions = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchSuggestions(query);
    });
  }

  void _selectLocation(dynamic feature) {
    try {
      final coordinates = feature['geometry']['coordinates'];
      final double lon = coordinates[0];
      final double lat = coordinates[1];
      final props = feature['properties'];

      String name = props['name'] ?? "";
      String city = props['city'] ?? props['state'] ?? props['country'] ?? "Vị trí ghim";
      String displayName = name.isEmpty ? city : (city.isNotEmpty && city != name ? "$name, $city" : name);

      FocusScope.of(context).unfocus();

      setState(() {
        _suggestions = [];
        _searchController.value = TextEditingValue(
          text: displayName,
          selection: TextSelection.collapsed(offset: displayName.length),
        );
      });

      _mapController.move(LatLng(lat, lon), 15.0);
    } catch (e) {
      print("Lỗi parse tọa độ: $e");
    }
  }

  // ==========================================
  // GPS & WEATHER
  // ==========================================
  Future<void> _moveToCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      LatLng newLoc = LatLng(position.latitude, position.longitude);

      setState(() => _userLocation = newLoc);
      _mapController.move(newLoc, 15.0);

      if (mounted) {
        final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
        weatherProvider.fetchWeather(position.latitude, position.longitude);
        weatherProvider.initRealtimeWeatherAlerts();
      }
    } catch (e) {
      print("Lỗi GPS: $e");
    }
  }

  void _showWeatherDialog() {
    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
    if (weatherProvider.currentWeather == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chưa có dữ liệu thời tiết. Vui lòng đợi hoặc bật GPS.")));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(
          children: [
            WeatherInfoCard(weather: weatherProvider.currentWeather!),
          ],
        ),
      ),
    );
  }

  void _showMapStyleDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return _MapStyleSheet(
          mapStyles: _mapStyles,
          currentMapUrl: _currentMapUrl,
          onSelect: (style) {
            setState(() {
              _currentMapUrl = style['url'] as String;
              _currentMapName = style['name'] as String;
            });
            Navigator.pop(ctx);
          },
        );
      },
    );
  }

  void _toggleLegend() {
    setState(() => _showLegend = !_showLegend);
    if (_showLegend) {
      _legendAnimController.forward();
    } else {
      _legendAnimController.reverse();
    }
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);
    // ✅ Lấy chiều cao thực của màn hình (bao gồm cả status bar)
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── 1. MAP ──────────────────────────────────
          // ✅ Bọc trong SizedBox để map luôn chiếm đúng 100% chiều cao màn hình
          SizedBox(
            width: double.infinity,
            height: screenHeight,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(10.762622, 106.660172),
                initialZoom: 13.0,
                // ✅ Giới hạn zoom tối thiểu để tránh khoảng trắng xung quanh bản đồ
                minZoom: 3.0,
                onPositionChanged: (position, hasGesture) {
                  if (hasGesture && position.center != null) {
                    FocusScope.of(context).unfocus();
                    if (_suggestions.isNotEmpty) {
                      setState(() => _suggestions = []);
                    }
                  }
                },
                onTap: (_, __) {
                  FocusScope.of(context).unfocus();
                  setState(() => _suggestions = []);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: _currentMapUrl,
                  userAgentPackageName: 'vn.edu.umt.floodwarning',
                ),
                MarkerLayer(
                  markers: [
                    ...reportProvider.reports.map((report) {
                      return Marker(
                        point: LatLng(report.lat, report.long),
                        width: 56, height: 64,
                        child: GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => ReportDetailModal(report: report),
                            );
                          },
                          child: _FloodMarker(),
                        ),
                      );
                    }),
                    if (_userLocation != null)
                      Marker(
                        point: _userLocation!,
                        width: 22, height: 22,
                        child: _UserLocationDot(),
                      ),
                  ],
                ),
              ],
            ),
          ), // ✅ Đóng SizedBox

          // ── 2. TOP BAR & SEARCH ──────────────
          SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: IconButton(
                          icon: const Icon(Icons.logout, color: Colors.redAccent),
                          onPressed: () {
                            Provider.of<AuthProvider>(context, listen: false).logout();
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 2))]
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: "Nhập tên thành phố, khu vực...",
                            prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                            suffixIcon: _isLoadingSuggestions
                                ? const Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(strokeWidth: 2))
                                : IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _suggestions = []);
                              },
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 60, right: 16),
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]
                    ),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1, color: Colors.grey),
                      itemBuilder: (ctx, index) {
                        final item = _suggestions[index];
                        final props = item['properties'];

                        final String name = props['name'] ?? "Không tên";
                        final String details = [props['city'], props['district'], props['country']].where((e) => e != null).join(", ");

                        return ListTile(
                          leading: const Icon(Icons.location_on_outlined, color: Colors.grey),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(details, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                          onTap: () => _selectLocation(item),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // ── 3. MAP NAME BADGE ────────────────────────
          Positioned(
            bottom: 110,
            left: 16,
            child: _MapNameBadge(name: _currentMapName),
          ),

          // ── 4. LEGEND ────────────────────────────────
          Positioned(
            bottom: 160,
            left: 16,
            child: FadeTransition(
              opacity: _legendAnim,
              child: ScaleTransition(
                scale: _legendAnim,
                alignment: Alignment.bottomLeft,
                child: _showLegend ? _LegendCard() : const SizedBox.shrink(),
              ),
            ),
          ),

          // ── 5. FAB CLUSTER (bottom right) ────────────
          Positioned(
            bottom: 110,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FabButton(
                  heroTag: 'btn_weather',
                  icon: CupertinoIcons.cloud_sun_fill,
                  color: Colors.white,
                  iconColor: const Color(0xFF5856D6),
                  onTap: _showWeatherDialog,
                  tooltip: 'Xem thời tiết',
                ),
                const SizedBox(height: 10),
                _FabButton(
                  heroTag: 'btn_legend',
                  icon: CupertinoIcons.info_circle_fill,
                  color: _showLegend ? const Color(0xFFFF9500) : Colors.white,
                  iconColor: _showLegend ? Colors.white : const Color(0xFFFF9500),
                  onTap: _toggleLegend,
                  tooltip: 'Chú thích',
                ),
                const SizedBox(height: 10),
                _FabButton(
                  heroTag: 'btn_map_layer',
                  icon: CupertinoIcons.layers_fill,
                  color: Colors.white,
                  iconColor: const Color(0xFF30B0C7),
                  onTap: _showMapStyleDialog,
                  tooltip: 'Lớp bản đồ',
                ),
                const SizedBox(height: 10),
                _FabButton(
                  heroTag: 'btn_gps_main',
                  icon: CupertinoIcons.location_fill,
                  color: const Color(0xFF007AFF),
                  iconColor: Colors.white,
                  onTap: _moveToCurrentLocation,
                  tooltip: 'Vị trí của bạn',
                ),
              ],
            ),
          ),

          // ── 6. LOADING ───────────────────────────────
          if (reportProvider.isLoading && reportProvider.reports.isEmpty)
            const Center(child: CupertinoActivityIndicator(radius: 16)),
        ],
      ),
    );
  }
}

// ============================================================
// CÁC COMPONENT PHỤ TRỢ (GIỮ NGUYÊN)
// ============================================================

class _FloodMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: Colors.white, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: const Color(0xFFFF3B30).withOpacity(0.35), blurRadius: 10, spreadRadius: 3, offset: const Offset(0, 3))],
          ),
          child: const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Color(0xFFFF3B30), size: 22),
        ),
        ClipPath(
          clipper: _TriangleClipper(),
          child: Container(width: 10, height: 7, color: Colors.white),
        ),
      ],
    );
  }
}

class _UserLocationDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(width: 22, height: 22, decoration: BoxDecoration(color: const Color(0xFF007AFF).withOpacity(0.2), shape: BoxShape.circle)),
        Container(
          width: 14, height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF007AFF), shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [BoxShadow(color: const Color(0xFF007AFF).withOpacity(0.5), blurRadius: 8, spreadRadius: 2)],
          ),
        ),
      ],
    );
  }
}

class _MapNameBadge extends StatelessWidget {
  final String name;
  const _MapNameBadge({required this.name});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.layers_fill, color: Colors.white70, size: 13),
          const SizedBox(width: 5),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _LegendCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Chú thích bản đồ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1C1C1E))),
          const SizedBox(height: 10),
          _LegendItem(icon: CupertinoIcons.exclamationmark_triangle_fill, color: const Color(0xFFFF3B30), label: 'Điểm ngập lụt', sublabel: 'Báo cáo từ cộng đồng'),
          const SizedBox(height: 8),
          _LegendItem(icon: CupertinoIcons.location_fill, color: const Color(0xFF007AFF), label: 'Vị trí của bạn', sublabel: 'Định vị GPS thời gian thực'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final IconData icon; final Color color; final String label; final String sublabel;
  const _LegendItem({required this.icon, required this.color, required this.label, required this.sublabel});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1C1C1E))),
            Text(sublabel, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
          ],
        ),
      ],
    );
  }
}

class _FabButton extends StatelessWidget {
  final String heroTag; final IconData icon; final Color color; final Color iconColor; final VoidCallback onTap; final String tooltip;
  const _FabButton({required this.heroTag, required this.icon, required this.color, required this.iconColor, required this.onTap, required this.tooltip});
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: color == Colors.white ? Colors.black.withOpacity(0.15) : color.withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
      ),
    );
  }
}

class _MapStyleSheet extends StatelessWidget {
  final List<Map<String, dynamic>> mapStyles; final String currentMapUrl; final void Function(Map<String, dynamic>) onSelect;
  const _MapStyleSheet({required this.mapStyles, required this.currentMapUrl, required this.onSelect});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFFF2F2F7), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(margin: const EdgeInsets.only(top: 10, bottom: 6), width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFD1D1D6), borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 6, 20, 14),
              child: Row(children: [Text('Chọn lớp bản đồ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E)))]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GridView.builder(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.95),
                itemCount: mapStyles.length,
                itemBuilder: (_, i) {
                  final style = mapStyles[i]; final isSelected = currentMapUrl == style['url']; final color = style['color'] as Color;
                  return GestureDetector(
                    onTap: () => onSelect(style),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.12) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: color.withOpacity(0.13), borderRadius: BorderRadius.circular(12)),
                            child: Icon(style['icon'] as IconData, color: color, size: 22),
                          ),
                          const SizedBox(height: 8),
                          Text(style['name'] as String, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: isSelected ? color : const Color(0xFF1C1C1E)), textAlign: TextAlign.center),
                          const SizedBox(height: 2),
                          Text(style['subtitle'] as String, style: const TextStyle(fontSize: 10, color: Color(0xFF8E8E93)), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (isSelected) ...[const SizedBox(height: 4), Icon(CupertinoIcons.checkmark_circle_fill, color: color, size: 16)],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}