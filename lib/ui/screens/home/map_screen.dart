import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../providers/network_sync_provider.dart';
import '../../widgets/offline_banner.dart';

import '../../../providers/report_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/sos_provider.dart';
import '../../../providers/weather_provider.dart';
import '../../widgets/report_detail_modal.dart';
import '../../widgets/weather_info_card.dart';

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
    {'name': 'Tiêu chuẩn', 'subtitle': 'OpenStreetMap', 'url': 'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png', 'icon': CupertinoIcons.map, 'color': const Color(0xFF007AFF)},
    {'name': 'Nhân đạo', 'subtitle': 'Cứu trợ thiên tai', 'url': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', 'icon': CupertinoIcons.heart_fill, 'color': const Color(0xFFFF3B30)},
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

  String _currentWeatherLayer = 'none';

  final List<Map<String, dynamic>> _weatherLayers = [
    {'id': 'none', 'name': 'Tắt radar', 'icon': Icons.layers_clear},
    {
      'id': 'temp', 'name': 'Nhiệt độ', 'icon': CupertinoIcons.thermometer,
      'unit': '°C', 'min': '-40', 'max': '40+',
      'colors': [
        const Color(0xFF821692), // Tím (-40)
        const Color(0xFF381395), // Indigo (-20)
        const Color(0xFF1F5F99), // Xanh lam nhạt (-10)
        const Color(0xFF20C4E8), // Xanh ngọc (0)
        const Color(0xFF34C759), // Xanh lá (10)
        const Color(0xFFFFCC00), // Vàng (20)
        const Color(0xFFFF9500), // Cam (30)
        const Color(0xFFFF3B30), // Đỏ (40+)
      ]
    },
    {
      'id': 'precipitation', 'name': 'Lượng mưa', 'icon': CupertinoIcons.drop_fill,
      'unit': 'mm/h', 'min': '0', 'max': '140',
      'colors': [
        Colors.transparent,
        const Color(0xFFE2FBA0), // Vàng chanh nhạt (0.1)
        const Color(0xFF75D92A), // Xanh lá (2)
        const Color(0xFF24CAE3), // Xanh lơ (10)
        const Color(0xFF163BF1), // Xanh lam đậm (20)
        const Color(0xFF8B12F2), // Tím (50)
        const Color(0xFFF3134C), // Đỏ (140)
      ]
    },
    {
      'id': 'wind', 'name': 'Sức gió', 'icon': CupertinoIcons.wind,
      'unit': 'm/s', 'min': '0', 'max': '100',
      'colors': [
        Colors.transparent,
        const Color(0xFFFFFF00), // Vàng (10)
        const Color(0xFFFF9900), // Cam (20)
        const Color(0xFFFF0000), // Đỏ (50)
        const Color(0xFF9900FF), // Tím (100)
      ]
    },
    {
      'id': 'pressure', 'name': 'Áp suất', 'icon': CupertinoIcons.gauge,
      'unit': 'hPa', 'min': '940', 'max': '1080',
      'colors': [
        const Color(0xFF0073FF), // 940
        const Color(0xFF55D0FF), // 980
        const Color(0xFFFFF028), // 1010
        const Color(0xFFFFAA00), // 1020
        const Color(0xFFBD003D), // 1080
      ]
    },
    {
      'id': 'clouds', 'name': 'Đám mây', 'icon': CupertinoIcons.cloud_fill,
      'unit': '%', 'min': '0', 'max': '100',
      'colors': [
        Colors.transparent,
        Colors.white54,
        Colors.white,
      ]
    },
  ];

  String _getWeatherLayerUrl() {
    if (_currentWeatherLayer == 'none') return '';
    final apiKey = dotenv.env['OWM_API_KEY'] ?? '';
    return 'https://tile.openweathermap.org/map/${_currentWeatherLayer}_new/{z}/{x}/{y}.png?appid=$apiKey';
  }

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

  // HÀM TÌM KIẾM
  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) {
      if (mounted) setState(() { _suggestions = []; _isLoadingSuggestions = false; });
      return;
    }
    _cancelToken?.cancel("Cancelled due to new request");
    _cancelToken = CancelToken();
    if (mounted) setState(() => _isLoadingSuggestions = true);

    try {
      final url = "https://photon.komoot.io/api/?q=$query&limit=5&lang=en";
      final response = await Dio().get(url, cancelToken: _cancelToken, options: Options(headers: {'User-Agent': 'FloodWarningMobileApp/1.0'}));
      if (response.statusCode == 200 && mounted) {
        setState(() { _suggestions = response.data['features'] as List; _isLoadingSuggestions = false; });
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return;
      print("❌ Lỗi tìm kiếm Photon: $e");
      if (mounted) setState(() => _isLoadingSuggestions = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _fetchSuggestions(query));
  }

  void _selectLocation(dynamic feature) {
    try {
      final coordinates = feature['geometry']['coordinates'];
      final double lon = coordinates[0]; final double lat = coordinates[1];
      final props = feature['properties'];
      String name = props['name'] ?? "";
      String city = props['city'] ?? props['state'] ?? props['country'] ?? "Vị trí ghim";
      String displayName = name.isEmpty ? city : (city.isNotEmpty && city != name ? "$name, $city" : name);

      FocusScope.of(context).unfocus();
      setState(() {
        _suggestions = [];
        _searchController.value = TextEditingValue(text: displayName, selection: TextSelection.collapsed(offset: displayName.length));
      });
      _mapController.move(LatLng(lat, lon), 15.0);
    } catch (e) {
      print("Lỗi parse tọa độ: $e");
    }
  }

  // GPS & WEATHER
  Future<void> _moveToCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      Position position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
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
        backgroundColor: Colors.transparent, elevation: 0, insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(children: [WeatherInfoCard(weather: weatherProvider.currentWeather!)]),
      ),
    );
  }

  void _showMapStyleDialog() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (ctx) {
        return _MapStyleSheet(
          mapStyles: _mapStyles, currentMapUrl: _currentMapUrl,
          onSelect: (style) {
            setState(() { _currentMapUrl = style['url'] as String; _currentMapName = style['name'] as String; });
            Navigator.pop(ctx);
          },
        );
      },
    );
  }

  void _toggleLegend() {
    setState(() => _showLegend = !_showLegend);
    if (_showLegend) _legendAnimController.forward(); else _legendAnimController.reverse();
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);
    final isOffline = context.watch<NetworkSyncProvider>().isOffline;
    final double screenHeight = MediaQuery.of(context).size.height;

    // Lấy cấu hình của lớp Radar đang chọn
    final currentLayerConfig = _weatherLayers.firstWhere((layer) => layer['id'] == _currentWeatherLayer);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── 1. MAP ──────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: screenHeight,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(10.762622, 106.660172),
                initialZoom: 13.0,
                minZoom: 3.0,
                onPositionChanged: (position, hasGesture) {
                  if (hasGesture && position.center != null) {
                    FocusScope.of(context).unfocus();
                    if (_suggestions.isNotEmpty) setState(() => _suggestions = []);
                  }
                },
                onTap: (_, __) {
                  FocusScope.of(context).unfocus();
                  setState(() => _suggestions = []);
                  if (_showLegend) _toggleLegend();
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: _currentMapUrl,
                  userAgentPackageName: 'vn.edu.umt.floodwarning',
                  tileProvider: _currentMapName == 'Tiêu chuẩn' ? FMTCStore('fws_offline_map').getTileProvider() : null,
                ),

                if (_currentWeatherLayer != 'none')
                  TileLayer(urlTemplate: _getWeatherLayerUrl()),

                MarkerLayer(
                  markers: [
                    ...reportProvider.reports.map((report) {
                      return Marker(
                        point: LatLng(report.lat, report.long),
                        width: 56, height: 64,
                        child: GestureDetector(
                          onTap: () {
                            showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => ReportDetailModal(report: report));
                          },
                          child: _FloodMarker(status: report.status),
                        ),
                      );
                    }),
                    if (_userLocation != null)
                      Marker(point: _userLocation!, width: 22, height: 22, child: _UserLocationDot()),
                  ],
                ),
              ],
            ),
          ),

          // ── 2. TOP BAR, SEARCH & PILLS ──────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isOffline) const OfflineBanner(),

                // Ô Tìm Kiếm và nút SOS
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Consumer<SosProvider>(
                          builder: (context, sosProvider, child) {
                            return GestureDetector(
                              onTap: sosProvider.isLoading ? null : () {
                                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                String currentUserId = authProvider.user?.id.toString() ?? "0";
                                sosProvider.triggerSOS(context, currentUserId, "FLOOD");
                              },
                              child: Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.5), blurRadius: 15, spreadRadius: 2)]),
                                child: sosProvider.isLoading
                                    ? const Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.sos_rounded, color: Colors.white, size: 28, weight: 800),
                              ),
                            );
                          }
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                        decoration: BoxDecoration(color: isOffline ? Colors.grey.shade200 : Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 2))]),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          enabled: !isOffline,
                          decoration: InputDecoration(
                            hintText: isOffline ? "Khóa khi ngoại tuyến" : "Nhập tên thành phố, khu vực...",
                            hintStyle: TextStyle(color: isOffline ? Colors.grey : Colors.black54, fontSize: 14),
                            prefixIcon: Icon(Icons.search, color: isOffline ? Colors.grey : Colors.blueAccent),
                            suffixIcon: _isLoadingSuggestions
                                ? const Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(strokeWidth: 2))
                                : IconButton(icon: Icon(Icons.clear, color: isOffline ? Colors.transparent : Colors.grey), onPressed: isOffline ? null : () { _searchController.clear(); setState(() => _suggestions = []); }),
                            border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // === PILL BUTTONS (CHỌN LỚP RADAR) ===
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _weatherLayers.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final layer = _weatherLayers[index];
                      final isSelected = _currentWeatherLayer == layer['id'];
                      return GestureDetector(
                        onTap: () {
                          setState(() { _currentWeatherLayer = layer['id'] as String; });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300),
                              boxShadow: [
                                if (isSelected) BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))
                              ]
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(layer['icon'] as IconData, size: 16, color: isSelected ? Colors.white : Colors.black87),
                              const SizedBox(width: 6),
                              Text(layer['name'] as String, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? Colors.white : Colors.black87)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // === BẢNG CHÚ THÍCH MÀU SẮC RADAR CHUẨN OWM ===
                if (_currentWeatherLayer != 'none')
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))]
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(currentLayerConfig['min'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Container(
                            width: 100, height: 12,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: LinearGradient(colors: currentLayerConfig['colors'] as List<Color>),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text("${currentLayerConfig['max']} ${currentLayerConfig['unit']}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),

                // Danh sách gợi ý tìm kiếm
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 60, right: 16, top: 10),
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]),
                    child: ListView.separated(
                      padding: EdgeInsets.zero, shrinkWrap: true, itemCount: _suggestions.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1, color: Colors.grey),
                      itemBuilder: (ctx, index) {
                        final item = _suggestions[index]; final props = item['properties'];
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

          // ── 3. KHỐI GÓC DƯỚI TRÁI: TÊN BẢN ĐỒ & CHÚ THÍCH NGẬP LỤT ──
          Positioned(
            bottom: 110,
            left: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MapNameBadge(name: _currentMapName),

                FadeTransition(
                  opacity: _legendAnim,
                  child: SizeTransition(
                    sizeFactor: _legendAnim,
                    axisAlignment: -1.0,
                    child: _showLegend
                        ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _LegendCard(),
                    )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),

          // ── 4. FAB CLUSTER (bottom right) ────────────
          Positioned(
            bottom: 110,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FabButton(heroTag: 'btn_weather', icon: CupertinoIcons.cloud_sun_fill, color: Colors.white, iconColor: const Color(0xFF30B0C7), onTap: _showWeatherDialog, tooltip: 'Xem thời tiết'),
                const SizedBox(height: 10),
                _FabButton(heroTag: 'btn_legend', icon: CupertinoIcons.info_circle_fill, color: _showLegend ? const Color(0xFFFF9500) : Colors.white, iconColor: _showLegend ? Colors.white : const Color(0xFFFF9500), onTap: _toggleLegend, tooltip: 'Chú thích'),
                const SizedBox(height: 10),
                _FabButton(heroTag: 'btn_map_layer', icon: CupertinoIcons.layers_fill, color: Colors.white, iconColor: const Color(0xFF2563EB), onTap: _showMapStyleDialog, tooltip: 'Lớp bản đồ'),
                const SizedBox(height: 10),
                _FabButton(heroTag: 'btn_gps_main', icon: CupertinoIcons.location_fill, color: const Color(0xFF007AFF), iconColor: Colors.white, onTap: _moveToCurrentLocation, tooltip: 'Vị trí của bạn'),
              ],
            ),
          ),

          // ── 5. LOADING ───────────────────────────────
          if (reportProvider.isLoading && reportProvider.reports.isEmpty)
            const Center(child: CupertinoActivityIndicator(radius: 16)),
        ],
      ),
    );
  }
}

// CÁC COMPONENT PHỤ TRỢ

class _FloodMarker extends StatelessWidget {
  final String status;
  const _FloodMarker({required this.status});

  Color _getStatusColor() {
    switch (status) {
      case 'verified': return const Color(0xFF059669);
      case 'rejected': return const Color(0xFFDC2626);
      case 'pending': default: return const Color(0xFFD97706);
    }
  }

  @override
  Widget build(BuildContext context) {
    final markerColor = _getStatusColor();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: Colors.white, shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: markerColor.withValues(alpha: 0.45), blurRadius: 10, spreadRadius: 3, offset: const Offset(0, 3)
              )
            ],
          ),
          child: Icon(CupertinoIcons.exclamationmark_triangle_fill, color: markerColor, size: 22),
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
        Container(width: 22, height: 22, decoration: BoxDecoration(color: const Color(0xFF007AFF).withValues(alpha: 0.2), shape: BoxShape.circle)),
        Container(
          width: 14, height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF007AFF), shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [BoxShadow(color: const Color(0xFF007AFF).withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)],
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
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(20)),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Chú thích báo cáo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1C1C1E))),
          const SizedBox(height: 10),
          _LegendItem(icon: CupertinoIcons.exclamationmark_triangle_fill, color: const Color(0xFF059669), label: 'Đã xác minh', sublabel: 'Thông tin tin cậy'),
          const SizedBox(height: 8),
          _LegendItem(icon: CupertinoIcons.exclamationmark_triangle_fill, color: const Color(0xFFD97706), label: 'Chờ duyệt', sublabel: 'Mới được gửi lên'),
          const SizedBox(height: 8),
          _LegendItem(icon: CupertinoIcons.exclamationmark_triangle_fill, color: const Color(0xFFDC2626), label: 'Bị từ chối', sublabel: 'Báo cáo không đúng'),
          const SizedBox(height: 8),
          _LegendItem(icon: CupertinoIcons.location_fill, color: const Color(0xFF007AFF), label: 'Vị trí của bạn', sublabel: 'Định vị GPS'),
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
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
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
            boxShadow: [BoxShadow(color: color == Colors.white ? Colors.black.withValues(alpha: 0.15) : color.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 4))],
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
                        color: isSelected ? color.withValues(alpha: 0.12) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(12)),
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