import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/models/contact_model.dart';
import '../data/repositories/contact_repository.dart';
import '../data/services/hive_service.dart';

class ContactProvider with ChangeNotifier {
  final ContactRepository _repository = ContactRepository();
  final String _cacheKey = 'emergency_contacts_cache';

  List<EmergencyContact> _systemContacts = [];
  List<EmergencyContact> _localContacts = [];
  List<EmergencyContact> _customContacts = [];
  bool _isLoading = false;

  List<EmergencyContact> get systemContacts => _systemContacts;
  List<EmergencyContact> get localContacts => _localContacts;
  List<EmergencyContact> get customContacts => _customContacts;
  List<EmergencyContact> get allContacts => [..._systemContacts, ..._localContacts, ..._customContacts];
  bool get isLoading => _isLoading;

  // Lấy danh sách (Offline-first)
  Future<void> fetchContacts() async {
    _isLoading = true;
    notifyListeners();

    var connectivityResult = await (Connectivity().checkConnectivity());
    bool hasInternet = !connectivityResult.contains(ConnectivityResult.none);

    if (hasInternet) {
      try {
        double? lat;
        double? lon;

        // TỰ ĐỘNG LẤY GPS ĐỂ TÌM TRẠM CỨU HỘ GẦN NHẤT
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
            Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
            lat = position.latitude;
            lon = position.longitude;
          }
        }

        final data = await _repository.getAllContacts(lat: lat, long: lon);

        if (data != null) {
          _systemContacts = (data['system_contacts'] as List?)?.map((e) => EmergencyContact.fromJson(e)).toList() ?? [];
          _localContacts = (data['local_contacts'] as List?)?.map((e) => EmergencyContact.fromJson(e)).toList() ?? [];
          _customContacts = (data['custom_contacts'] as List?)?.map((e) => EmergencyContact.fromJson(e, isCustom: true)).toList() ?? [];

          // Lưu cache JSON vào Hive (gồm cả 3 mảng)
          Map<String, dynamic> cacheData = {
            'system_contacts': _systemContacts.map((e) => e.toJson()).toList(),
            'local_contacts': _localContacts.map((e) => e.toJson()).toList(),
            'custom_contacts': _customContacts.map((e) => e.toJson()).toList(),
          };
          await HiveService.dataBox.put(_cacheKey, jsonEncode(cacheData));
        }
      } catch (e) {
        print("Lỗi fetch danh bạ: $e");
        _loadLocalData();
      }
    } else {
      _loadLocalData();
    }

    _isLoading = false;
    notifyListeners();
  }

  void _loadLocalData() {
    final String? cached = HiveService.dataBox.get(_cacheKey);
    if (cached != null) {
      final data = jsonDecode(cached);
      _systemContacts = (data['system_contacts'] as List?)?.map((e) => EmergencyContact.fromJson(e)).toList() ?? [];
      _localContacts = (data['local_contacts'] as List?)?.map((e) => EmergencyContact.fromJson(e)).toList() ?? [];
      _customContacts = (data['custom_contacts'] as List?)?.map((e) => EmergencyContact.fromJson(e, isCustom: true)).toList() ?? [];
    }
  }

  // One-tap Call
  Future<void> makeCall(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  // SMS kèm tọa độ GPS
  Future<void> sendEmergencySMS(String phoneNumber) async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      // Fix link bản đồ chuẩn Google Maps
      String mapUrl = "http://maps.google.com/maps?q=${position.latitude},${position.longitude}";
      String message = "TÔI ĐANG GẶP NGUY HIỂM. Vị trí của tôi: $mapUrl";

      final Uri url = Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(url)) await launchUrl(url);
    } catch (e) {
      print("Không lấy được tọa độ: $e");
    }
  }

  // Xóa liên hệ
  Future<void> deleteContact(String id) async {
    final success = await _repository.deleteCustomContact(id);
    if (success) {
      _customContacts.removeWhere((element) => element.id == id);
      notifyListeners();
    }
  }

  // Add contacs
  Future<bool> addContact(String name, String phone, String relation) async {
    final newContact = await _repository.addCustomContact(name, phone, relation);
    if (newContact != null) {
      _customContacts.add(newContact);
      notifyListeners();
      return true;
    }
    return false;
  }
}