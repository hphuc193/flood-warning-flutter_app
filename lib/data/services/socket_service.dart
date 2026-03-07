import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  late IO.Socket _socket;

  // URL Socket từ server của bạn
  // Lưu ý: Render dùng wss (secure) nên cần cấu hình đúng
  final String _serverUrl = 'https://flood-warning-backend.onrender.com';

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  void initSocket() {
    _socket = IO.io(_serverUrl, IO.OptionBuilder()
        .setTransports(['websocket']) // Bắt buộc dùng websocket để tối ưu
        .disableAutoConnect() // Tắt tự động kết nối lúc init để mình control
        .build());

    _socket.connect();

    _socket.onConnect((_) {
      print('✅ Socket Connected: ${_socket.id}');
    });

    _socket.onDisconnect((_) {
      print('❌ Socket Disconnected');
    });

    _socket.onError((data) => print('Socket Error: $data'));
  }

  // Hàm lắng nghe sự kiện cụ thể
  void onNewFloodReport(Function(dynamic) callback) {
    _socket.on('new_flood_report', (data) {
      print('🔔 New Flood Alert Received: $data');
      callback(data);
    });
  }

  void onWeatherUpdate(Function(dynamic) callback) {
    _socket.on('weather_update', (data) {
      print('⛈️ Weather Update: $data');
      callback(data);
    });
  }

  void disconnect() {
    _socket.disconnect();
  }
}