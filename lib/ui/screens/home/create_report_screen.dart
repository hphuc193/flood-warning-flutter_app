import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
// Nhớ import file MapPickerScreen mà chúng ta sẽ tạo ở Bước 2
import 'map_picker_screen.dart';
import '../../../providers/report_provider.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _descController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];

  // Tách riêng Lat/Lng để dễ cập nhật từ Map
  double? _latitude;
  double? _longitude;
  bool _gettingLocation = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Hàm lấy vị trí GPS
  Future<void> _getCurrentLocation() async {
    setState(() => _gettingLocation = true);
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _gettingLocation = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _gettingLocation = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _gettingLocation = false);
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
      _gettingLocation = false;
    });
  }

  // Hàm mở màn hình chọn bản đồ
  Future<void> _openMapPicker() async {
    // Chuyển sang màn hình Map, đợi kết quả trả về
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerScreen()),
    );

    // Nếu người dùng chọn xong và trả về mảng [lat, lng]
    if (result != null && result is List<double>) {
      setState(() {
        _latitude = result[0];
        _longitude = result[1];
        _gettingLocation = false;
      });
    }
  }

  // Hàm chọn ảnh
  Future<void> _pickImage() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Báo cáo điểm ngập")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Phần hiển thị tọa độ đã được nâng cấp
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.blue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _gettingLocation
                            ? const Text("Đang lấy tọa độ...")
                            : _latitude != null
                            ? Text(
                          "Vĩ độ: ${_latitude!.toStringAsFixed(5)}\nKinh độ: ${_longitude!.toStringAsFixed(5)}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                            : const Text("Chưa có vị trí. Hãy bật GPS hoặc chọn trên bản đồ."),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  // Hai nút công cụ: Dùng GPS hiện tại & Chọn trên bản đồ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.my_location, size: 18),
                        label: const Text("Dùng GPS"),
                      ),
                      ElevatedButton.icon(
                        onPressed: _openMapPicker,
                        icon: const Icon(Icons.map, size: 18),
                        label: const Text("Chọn trên bản đồ"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Nhập mô tả
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Mô tả tình trạng ngập",
                border: OutlineInputBorder(),
                hintText: "Ví dụ: Ngập sâu 0.5m, xe máy không đi được...",
              ),
            ),
            const SizedBox(height: 20),

            // 3. Chọn ảnh
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Hình ảnh hiện trường:", style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Thêm ảnh"),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_selectedImages.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (ctx, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: FileImage(File(_selectedImages[index].path)),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImages.removeAt(index);
                              });
                            },
                            child: Container(
                              color: Colors.black54,
                              child: const Icon(Icons.close, color: Colors.white, size: 20),
                            ),
                          ),
                        )
                      ],
                    );
                  },
                ),
              ),

            const SizedBox(height: 30),

            // 4. Nút Gửi
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: (reportProvider.isLoading || _latitude == null)
                    ? null
                    : () async {
                  if (_descController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập mô tả")));
                    return;
                  }

                  bool success = await reportProvider.createReport(
                      _latitude!,
                      _longitude!,
                      _descController.text,
                      _selectedImages.map((e) => e.path).toList(),
                      context
                  );

                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gửi báo cáo thành công!")));
                    Navigator.pop(context);
                  }
                },
                child: reportProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("GỬI BÁO CÁO NGAY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}