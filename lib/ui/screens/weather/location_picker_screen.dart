import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng _center = const LatLng(10.762622, 106.660172); // Mặc định HCM
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

  // --- HÀM TÌM KIẾM ĐÃ SỬA LỖI LOGIC ---
  // --- HÀM TÌM KIẾM ĐÃ SỬA LỖI 403 ---
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
      print("🔍 Đang tìm (Photon): $query");

      // ĐÃ SỬA: Thêm User-Agent vào cấu hình Options của Dio
      final response = await Dio().get(
        url,
        cancelToken: _cancelToken,
        options: Options(
          headers: {
            // Định danh rõ ràng để server Photon không chặn (bắt buộc)
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
        print("Đã hủy request cũ.");
      } else {
        print("❌ Lỗi tìm kiếm: $e");
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
      // Bóc tách dữ liệu từ GeoJSON của Photon
      final coordinates = feature['geometry']['coordinates'];
      // Photon trả về [lon, lat] thay vì [lat, lon]
      final double lon = coordinates[0];
      final double lat = coordinates[1];

      final props = feature['properties'];

      String name = props['name'] ?? "";
      String city = props['city'] ?? props['state'] ?? props['country'] ?? "Vị trí ghim";

      String displayName = name;
      if (name.isEmpty) {
        displayName = city;
      } else if (city.isNotEmpty && city != name) {
        displayName = "$name, $city";
      }

      // Ẩn bàn phím trước khi setState để tránh giật lag UI
      FocusScope.of(context).unfocus();

      setState(() {
        _center = LatLng(lat, lon);
        _selectedName = displayName;
        _suggestions = []; // Tắt danh sách gợi ý
        _searchController.text = displayName; // Điền tên vào ô search
      });

      // Di chuyển bản đồ đến điểm chọn
      _mapController.move(_center, 14.0);
    } catch (e) {
      print("Lỗi parse tọa độ Photon: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. BẢN ĐỒ LỚP DƯỚI CÙNG
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13.0,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture && position.center != null) {
                  setState(() {
                    _center = position.center!;
                    // Tự động đóng gợi ý khi kéo map
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
                userAgentPackageName: 'com.example.flood_warning',
              ),
            ],
          ),

          // 2. GHIM ĐỎ Ở GIỮA (Lớp thứ 2)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(Icons.location_on, size: 50, color: Colors.red),
            ),
          ),

          // 3. NÚT CHỌN BÊN DƯỚI CÙNG (Lớp thứ 3)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 5,
              ),
              onPressed: () {
                Navigator.pop(context, {
                  'lat': _center.latitude,
                  'long': _center.longitude,
                  'name': _selectedName
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        "XEM DỰ BÁO: $_selectedName",
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. NÚT BACK VÀ KHỐI TÌM KIẾM Ở TRÊN CÙNG (Lớp cao nhất)
          SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    // Nút Back
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),

                    // Ô Tìm kiếm
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 2))
                            ]
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: "Nhập tên thành phố...",
                            prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                            suffixIcon: _isLoadingSuggestions
                                ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
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

                // Danh sách gợi ý
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 60, right: 16), // Căn lề lùi vào bằng nút back
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                        ]
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
                        final String details = [
                          props['city'],
                          props['district'],
                          props['country']
                        ].where((e) => e != null).join(", ");

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