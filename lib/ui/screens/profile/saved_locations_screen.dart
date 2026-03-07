import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/location_provider.dart';
import '../../../data/models/saved_location_model.dart';
import '../weather/location_picker_screen.dart';

class SavedLocationsScreen extends StatefulWidget {
  const SavedLocationsScreen({super.key});

  @override
  State<SavedLocationsScreen> createState() => _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends State<SavedLocationsScreen> {
  @override
  void initState() {
    super.initState();
    // Tải danh sách từ Server khi mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LocationProvider>(context, listen: false).fetchLocations();
    });
  }

  // --- FORM THÊM VỊ TRÍ MỚI ---
  void _showAddLocationDialog(BuildContext context, double lat, double long) {
    final nameController = TextEditingController();
    double radius = 5.0; // Mặc định 5km
    String priority = 'medium';
    bool isActive = true;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 20, right: 20, top: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Thiết lập vị trí nhận cảnh báo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),

                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                            labelText: "Tên gợi nhớ (VD: Nhà riêng, Cty)",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.label)
                        ),
                      ),
                      const SizedBox(height: 15),

                      Text("Bán kính theo dõi: ${radius.round()} km", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Slider(
                        value: radius,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: "${radius.round()} km",
                        onChanged: (val) => setModalState(() => radius = val),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Mức độ ưu tiên:", style: TextStyle(fontWeight: FontWeight.bold)),
                          DropdownButton<String>(
                            value: priority,
                            items: const [
                              DropdownMenuItem(value: 'high', child: Text("Cao", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                              DropdownMenuItem(value: 'medium', child: Text("Trung bình", style: TextStyle(color: Colors.orange))),
                              DropdownMenuItem(value: 'low', child: Text("Thấp", style: TextStyle(color: Colors.green))),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => priority = val);
                            },
                          ),
                        ],
                      ),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Bật nhận cảnh báo ngập lụt"),
                        value: isActive,
                        activeColor: Colors.blueAccent,
                        onChanged: (val) => setModalState(() => isActive = val),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: const EdgeInsets.symmetric(vertical: 15)
                          ),
                          onPressed: () async {
                            if (nameController.text.trim().isEmpty) return;

                            final newLocation = SavedLocationModel(
                              name: nameController.text.trim(),
                              lat: lat,
                              long: long,
                              radius: radius,
                              priority: priority,
                              isActive: isActive,
                            );

                            // Gọi API lưu lên Server
                            final success = await Provider.of<LocationProvider>(context, listen: false).addLocation(newLocation);

                            if (success && ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Đã lưu vị trí cảnh báo!")));
                            }
                          },
                          child: const Text("LƯU THIẾT LẬP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              }
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Vị trí quan tâm"),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt, color: Colors.white),
            onPressed: () async {
              // 1. Mở map chọn tọa độ
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
              );

              // 2. Có tọa độ -> Mở Form thiết lập cấu hình cảnh báo
              if (result != null && result is Map<String, dynamic> && context.mounted) {
                _showAddLocationDialog(context, result['lat'], result['long']);
              }
            },
          )
        ],
      ),
      body: Consumer<LocationProvider>(
        builder: (context, locationProvider, child) {
          if (locationProvider.isLoading && locationProvider.locations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final locations = locationProvider.locations;

          if (locations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.not_listed_location, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text("Bạn chưa thiết lập vị trí nhận cảnh báo nào.", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Thêm vị trí mới"),
                    onPressed: () {
                      // Xử lý mở Map tương tự nút dấu + ở AppBar
                    },
                  )
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final loc = locations[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: loc.isActive ? Colors.blue[100] : Colors.grey[300],
                    child: Icon(
                      loc.priority == 'high' ? Icons.warning_amber_rounded
                          : loc.priority == 'medium' ? Icons.location_on
                          : Icons.notifications_none,
                      color: loc.isActive ? (loc.priority == 'high' ? Colors.red : Colors.blue) : Colors.grey,
                    ),
                  ),
                  title: Text(loc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("Bán kính: ${loc.radius.round()} km | Ưu tiên: ${loc.priority.toUpperCase()}"),
                      const SizedBox(height: 4),
                      Text(loc.isActive ? "Đang nhận cảnh báo" : "Đã tắt cảnh báo",
                          style: TextStyle(color: loc.isActive ? Colors.green : Colors.red, fontStyle: FontStyle.italic)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => locationProvider.deleteLocation(loc.id!), // Gọi API Xóa
                  ),
                  onTap: () {
                    // Mở dialog Update (nếu cần thiết kế tính năng sửa)
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}