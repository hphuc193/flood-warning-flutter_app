import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng _center = const LatLng(10.7626, 106.6602); // Mặc định HCM
  String _selectedName = "Vị trí đã chọn";

  Timer? _debounce;
  List<dynamic> _suggestions = [];
  bool _isLoadingSuggestions = false;
  CancelToken? _cancelToken;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _cancelToken?.cancel();
    super.dispose();
  }

  // Hàm gọi API tìm kiếm
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
      final url = "https://photon.komoot.io/api/?q=$query&limit=5&lang=vi"; // Đổi sang tiếng Việt cho dễ tìm

      final response = await Dio().get(
        url,
        cancelToken: _cancelToken,
        options: Options(
          headers: {
            'User-Agent': 'FloodWarningMobileApp/1.0',
            'Accept': 'application/json',
          },
        ),
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
        _center = LatLng(lat, lon);
        _selectedName = displayName;
        _suggestions = [];
        _searchController.text = displayName;
      });

      _mapController.move(_center, 15.0); // Zoom lại gần hơn khi chọn xong
    } catch (e) {
      print("Lỗi parse tọa độ: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. LỚP BẢN ĐỒ CƠ SỞ
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 14.0,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture && position.center != null) {
                  setState(() {
                    _center = position.center!;
                    if (_suggestions.isNotEmpty) _suggestions = [];
                  });
                }
              },
              onTap: (_, __) {
                FocusScope.of(context).unfocus();
                setState(() => _suggestions = []);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.hoangphuc.flood_warning',
              ),
            ],
          ),

          // 2. GHIM ĐỎ NẰM CỐ ĐỊNH Ở GIỮA
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40), // Cân bằng độ cao của Icon
              child: Icon(Icons.location_on, size: 50, color: Colors.red),
            ),
          ),

          // 3. NÚT XÁC NHẬN VỊ TRÍ
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent, // Đổi màu thành đỏ cho hợp với chức năng báo cáo
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 5,
              ),
              onPressed: () {
                // Trả mảng [lat, long] về cho CreateReportScreen
                Navigator.pop(context, [_center.latitude, _center.longitude]);
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text("XÁC NHẬN ĐIỂM NGẬP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ),

          // 4. THANH TÌM KIẾM TRÊN CÙNG
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
                          icon: const Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: () => Navigator.pop(context), // Trả về null
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 2))],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: "Tìm kiếm tên đường, khu vực...",
                            prefixIcon: const Icon(Icons.search, color: Colors.redAccent),
                            suffixIcon: _isLoadingSuggestions
                                ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                            )
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

                // 5. DANH SÁCH GỢI Ý THẢ XUỐNG
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
                        final String details = [props['city'], props['district'], props['country']]
                            .where((e) => e != null).join(", ");

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
        ],
      ),
    );
  }
}