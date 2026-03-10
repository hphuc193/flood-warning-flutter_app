import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/models/contact_model.dart';
import '../data/repositories/contact_repository.dart';

class ContactProvider with ChangeNotifier {
  final ContactRepository _repository = ContactRepository();
  final String _cacheKey = 'emergency_contacts_cache';

  List<EmergencyContact> _systemContacts = [];
  List<EmergencyContact> _customContacts = [];
  bool _isLoading = false;

  List<EmergencyContact> get allContacts => [..._systemContacts, ..._customContacts];
  bool get isLoading => _isLoading;

  // Lấy danh sách (Offline-first)
  Future<void> fetchContacts() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    var connectivityResult = await (Connectivity().checkConnectivity());

    if (connectivityResult != ConnectivityResult.none) {
      try {
        final data = await _repository.getAllContacts();
        if (data != null) {
          _systemContacts = data['system']!;
          _customContacts = data['custom']!;

          // Lưu cache JSON
          Map<String, dynamic> cacheData = {
            'system': _systemContacts.map((e) => e.toJson()).toList(),
            'custom': _customContacts.map((e) => e.toJson()).toList(),
          };
          await prefs.setString(_cacheKey, jsonEncode(cacheData));
        }
      } catch (e) {
        _loadLocalData(prefs);
      }
    } else {
      _loadLocalData(prefs);
    }

    _isLoading = false;
    notifyListeners();
  }

  void _loadLocalData(SharedPreferences prefs) {
    final String? cached = prefs.getString(_cacheKey);
    if (cached != null) {
      final data = jsonDecode(cached);
      _systemContacts = (data['system'] as List).map((e) => EmergencyContact.fromJson(e)).toList();
      _customContacts = (data['custom'] as List).map((e) => EmergencyContact.fromJson(e, isCustom: true)).toList();
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
      String mapUrl = "https://www.google.com/maps?q=${position.latitude},${position.longitude}";
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
      _customContacts.add(newContact); // Thêm vào mảng local
      notifyListeners(); // Báo UI update ngay lập tức
      return true;
    }
    return false;
  }
}