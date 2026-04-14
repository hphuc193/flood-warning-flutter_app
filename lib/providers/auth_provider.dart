import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/repositories/auth_repository.dart';
import '../data/models/user_model.dart' as model;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _isLoading = false;
  model.User? _user;
  String? _token;

  bool get isLoading => _isLoading;
  model.User? get user => _user;
  bool get isAuthenticated => _token != null;

  Future<bool> loginWithFacebook(BuildContext context) async {
    _setLoading(true);

    try {
      // 1. Kích hoạt flow đăng nhập Facebook từ Native SDK
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );

      if (result.status == LoginStatus.success) {
        // 2. Lấy Access Token từ Facebook
        final AccessToken accessToken = result.accessToken!;

        // 3. Đăng nhập vào Firebase Client
        final OAuthCredential credential = FacebookAuthProvider.credential(accessToken.tokenString);
        final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);

        // 4. LẤY ID TOKEN TỪ FIREBASE ĐỂ GỬI CHO BACKEND
        final String? idToken = await userCredential.user?.getIdToken();

        if (idToken != null) {
          // 5. Gọi API lên Node.js
          final response = await _authRepository.loginWithFacebook(idToken);

          if (response['success'] == true) {
            // 6. Bóc tách dữ liệu JSON Backend trả về
            final Map<String, dynamic> responseData = response['data'];

            _token = responseData['access_token'];
            _user = model.User.fromJson(responseData['user']);

            // Lưu vào storage máy điện thoại
            await _saveUserToStorage(responseData['user'], _token!);

            _setLoading(false);
            return true; // Đăng nhập thành công hoàn toàn!
          }
        }

        _setLoading(false);
        return false;
      } else {
        print("Facebook Login bị hủy hoặc lỗi: ${result.message}");
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print("Lỗi login Facebook: $e");
      if (context.mounted) {
        // Cực kỳ quan trọng: Lỗi này sẽ lấy được dòng chữ "Email này đã được đăng ký bằng phương thức khác..." từ BE của bạn để báo cho User.
        _showErrorDialog(context, e.toString());
      }
      _setLoading(false);
      return false;
    }
  }

  Future<bool> loginWithGoogle(BuildContext context) async {
    _setLoading(true);

    try {
      // 1. Kích hoạt luồng đăng nhập Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _setLoading(false);
        return false; // Người dùng hủy đăng nhập
      }

      // 2. Lấy thông tin xác thực từ request trên
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Tạo credential để đăng nhập vào Firebase (Client)
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Đăng nhập vào Firebase phía Client
      final UserCredential userCredential =
      await _firebaseAuth.signInWithCredential(credential);

      // 5. Lấy ID Token chuẩn từ Firebase User để gửi cho Backend
      final String? idToken = await userCredential.user?.getIdToken();

      if (idToken != null) {
        // 6. Gửi token này lên Backend để xác thực
        final response = await _authRepository.loginWithGoogle(idToken);

        if (response['success'] == true) {
          // Chui vào lớp 'data' bên trong JSON trả về
          final Map<String, dynamic> responseData = response['data'];

          // Lấy đúng key 'access_token' và 'user'
          _token = responseData['access_token'];
          _user = model.User.fromJson(responseData['user']);

          // Lưu vào storage
          await _saveUserToStorage(responseData['user'], _token!);

          _setLoading(false);
          return true; // Thành công
        }
      }
    } catch (e) {
      print("Lỗi Google Login: $e");
      if (context.mounted) {
        _showErrorDialog(context, "Đăng nhập Google thất bại: ${e.toString()}");
      }
    }

    _setLoading(false);
    return false;
  }

  // Login Logic
  Future<bool> login(String email, String password, BuildContext context) async {
    _setLoading(true);
    try {
      final data = await _authRepository.login(email, password);

      if (data['success'] == true) {
        _token = data['token'];
        _user = model.User.fromJson(data['user']);

        await _saveUserToStorage(data['user'], _token!);

        _setLoading(false);
        return true;
      }
    } catch (e) {
      _showErrorDialog(context, e.toString());
    }
    _setLoading(false);
    return false;
  }

  // Register Logic
  Future<bool> register(String email, String password, String fullName, BuildContext context) async {
    _setLoading(true);
    try {
      final data = await _authRepository.register(email, password, fullName);
      if (data['success'] == true) {
        _setLoading(false);
        return true;
      }
    } catch (e) {
      _showErrorDialog(context, e.toString());
    }
    _setLoading(false);
    return false;
  }

  // Logout
  Future<void> logout() async {
    _token = null;
    _user = null;
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'auth_user');
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thông báo'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Đóng'))
        ],
      ),
    );
  }

  //Hàm Tự Động Đăng Nhập
  Future<bool> tryAutoLogin() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return false; // Không có token -> Phải login

    final userStr = await _storage.read(key: 'auth_user');
    if (userStr == null) return false;

    try {
      // Khôi phục dữ liệu từ bộ nhớ
      _token = token;
      _user = model.User.fromJson(jsonDecode(userStr));
      notifyListeners(); // Báo cho UI biết đã có User
      return true;
    } catch (e) {
      return false;
    }
  }

  //Hàm lưu User vào máy
  Future<void> _saveUserToStorage(Map<String, dynamic> userData, String token) async {
    await _storage.write(key: 'auth_token', value: token);
    // Lưu thông tin user dưới dạng chuỗi JSON
    await _storage.write(key: 'auth_user', value: jsonEncode(userData));
  }
}