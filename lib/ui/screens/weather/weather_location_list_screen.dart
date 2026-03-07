import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/weather_provider.dart';
import 'location_picker_screen.dart';
import 'weather_main_screen.dart';

class WeatherLocationListScreen extends StatefulWidget {
  const WeatherLocationListScreen({super.key});

  @override
  State<WeatherLocationListScreen> createState() => _WeatherLocationListScreenState();
}

class _WeatherLocationListScreenState extends State<WeatherLocationListScreen> {
  @override
  void initState() {
    super.initState();
    // Load danh sách vị trí đã lưu khi mở tab này
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WeatherProvider>(context, listen: false).loadSavedLocations();
    });
  }

  // Hàm xử lý khi bấm vào 1 vị trí
  void _onLocationTapped(BuildContext context, String name, double lat, double lon) async {
    final provider = Provider.of<WeatherProvider>(context, listen: false);

    // 1. Hiện loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    // 2. Lấy dữ liệu 5 ngày cho vị trí này
    await provider.fetchForecast(lat, lon, cityName: name);

    // 3. Tắt loading
    if (context.mounted) Navigator.pop(context);

    // 4. Chuyển sang màn hình 5 ngày nếu có data
    if (provider.forecastData != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WeatherMainScreen(forecastData: provider.forecastData!),
        ),
      );
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lỗi tải dữ liệu. Vui lòng thử lại!")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý vị trí"),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt, color: Colors.white),
            onPressed: () async {
              // Mở màn hình chọn vị trí trên Map
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
              );

              // Nếu có chọn vị trí trả về, lưu vào danh sách
              if (result != null && result is Map<String, dynamic> && context.mounted) {
                Provider.of<WeatherProvider>(context, listen: false).addLocation(
                  result['name'] ?? 'Vị trí tùy chọn',
                  result['lat'],
                  result['long'], // Tùy vào key bạn trả về ở file picker
                );
              }
            },
          )
        ],
      ),
      body: Consumer<WeatherProvider>(
        builder: (context, weatherProvider, child) {
          final currentLoc = weatherProvider.currentLocation;
          final savedLocs = weatherProvider.savedLocations;

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Text("VỊ TRÍ HIỆN TẠI", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),

              // Thẻ Vị trí hiện tại
              Card(
                elevation: 3,
                color: Colors.blue[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: const Icon(Icons.my_location, color: Colors.blueAccent),
                  title: Text(currentLoc['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _onLocationTapped(context, currentLoc['name'], currentLoc['lat'], currentLoc['lon']),
                ),
              ),

              const SizedBox(height: 20),
              const Text("VỊ TRÍ ĐÃ LƯU", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),

              // Danh sách vị trí đã thêm
              if (savedLocs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(child: Text("Bạn chưa thêm vị trí nào.\nNhấn nút + trên góc phải để thêm.")),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: savedLocs.length,
                  itemBuilder: (context, index) {
                    final loc = savedLocs[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: const Icon(Icons.location_city, color: Colors.orange),
                        title: Text(loc['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Lat: ${loc['lat'].toStringAsFixed(2)}, Lon: ${loc['lon'].toStringAsFixed(2)}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => weatherProvider.removeLocation(index),
                        ),
                        onTap: () => _onLocationTapped(context, loc['name'], loc['lat'], loc['lon']),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}