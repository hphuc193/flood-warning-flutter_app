import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
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
  Position? _currentPosition;
  bool _gettingLocation = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Hàm lấy vị trí GPS
  Future<void> _getCurrentLocation() async {
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

    // Lấy vị trí
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
      _gettingLocation = false;
    });
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
            // 1. Phần hiển thị tọa độ
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _gettingLocation
                        ? const Text("Đang lấy tọa độ...")
                        : _currentPosition != null
                        ? Text(
                      "Vĩ độ: ${_currentPosition!.latitude.toStringAsFixed(5)}\nKinh độ: ${_currentPosition!.longitude.toStringAsFixed(5)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                        : const Text("Không lấy được vị trí. Hãy bật GPS."),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _getCurrentLocation,
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

            // Hiển thị list ảnh đã chọn
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
                onPressed: (reportProvider.isLoading || _currentPosition == null)
                    ? null
                    : () async {
                  if (_descController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập mô tả")));
                    return;
                  }

                  // Gọi Provider để gửi
                  bool success = await reportProvider.createReport(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                      _descController.text,
                      _selectedImages.map((e) => e.path).toList(),
                      context
                  );

                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gửi báo cáo thành công!")));
                    Navigator.pop(context); // Quay về bản đồ
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