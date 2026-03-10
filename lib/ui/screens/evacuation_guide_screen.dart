import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/evacuation_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'checklist_screen.dart'; // Import màn hình Checklist

class EvacuationGuideScreen extends StatefulWidget {
  const EvacuationGuideScreen({super.key});

  @override
  State<EvacuationGuideScreen> createState() => _EvacuationGuideScreenState();
}

class _EvacuationGuideScreenState extends State<EvacuationGuideScreen> {
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EvacuationProvider>(context, listen: false).fetchGuide();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hướng dẫn sơ tán", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent, // Màu đỏ cảnh báo
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<EvacuationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.steps.isEmpty) {
            return const Center(child: Text("Chưa có dữ liệu hướng dẫn."));
          }

          return Column(
            children: [
              // Cảnh báo Offline Mode
              if (provider.isOfflineMode)
                Container(
                  width: double.infinity,
                  color: Colors.orange[100],
                  padding: const EdgeInsets.all(8),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text("Đang hiển thị dữ liệu lưu ngoại tuyến", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

              Expanded(
                child: Stepper(
                  physics: const ClampingScrollPhysics(),
                  currentStep: _currentStep,
                  onStepTapped: (step) => setState(() => _currentStep = step),
                  onStepContinue: () {
                    if (_currentStep < provider.steps.length - 1) {
                      setState(() => _currentStep += 1);
                    }
                  },
                  onStepCancel: () {
                    if (_currentStep > 0) {
                      setState(() => _currentStep -= 1);
                    }
                  },
                  controlsBuilder: (context, details) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Row(
                        children: [
                          if (_currentStep < provider.steps.length - 1)
                            ElevatedButton(
                              onPressed: details.onStepContinue,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                              child: const Text('Tiếp tục'),
                            ),
                          const SizedBox(width: 8),
                          if (_currentStep > 0)
                            TextButton(
                              onPressed: details.onStepCancel,
                              child: const Text('Quay lại', style: TextStyle(color: Colors.grey)),
                            ),
                        ],
                      ),
                    );
                  },
                  // Duyệt mảng data để tạo các Step
                  steps: provider.steps.map((stepData) {
                    return Step(
                      isActive: _currentStep >= provider.steps.indexOf(stepData),
                      state: _currentStep > provider.steps.indexOf(stepData) ? StepState.complete : StepState.indexed,
                      title: Text(stepData.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. HIỂN THỊ CHỮ (Đã đổi thành stepData.description)
                          Text(stepData.description, style: const TextStyle(fontSize: 14, height: 1.5)),
                          const SizedBox(height: 16),

                          // 2. NÚT CHUYỂN HƯỚNG DỰA THEO TYPE
                          if (stepData.type == 'checklist_reference')
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChecklistScreen()));
                              },
                              icon: const Icon(Icons.backpack, color: Colors.white),
                              label: const Text("Mở túi khẩn cấp (Emergency Kit)"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                            ),

                          if (stepData.type == 'warning')
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.red[50], border: Border.all(color: Colors.red)),
                              child: const Row(
                                children: [
                                  Icon(Icons.warning_amber, color: Colors.red),
                                  SizedBox(width: 8),
                                  Expanded(child: Text("Đặc biệt chú ý quy tắc an toàn này!", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                                ],
                              ),
                            ),

                          // 3. NÚT XEM VIDEO (Nếu có URL)
                          if (stepData.videoUrl != null && stepData.videoUrl!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final Uri url = Uri.parse(stepData.videoUrl!);
                                  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Không thể mở video")));
                                  }
                                },
                                icon: const Icon(Icons.play_circle_fill, color: Colors.redAccent),
                                label: const Text("Xem Video hướng dẫn"),
                                style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.redAccent),
                                    foregroundColor: Colors.redAccent
                                ),
                              ),
                            )
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}