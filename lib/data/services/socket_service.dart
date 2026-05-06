import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  late IO.Socket _socket;
  IO.Socket get socket => _socket!;

  final String _serverUrl = 'https://flood-warning-backend.onrender.com';

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  void initSocket() {
    _socket = IO.io(_serverUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build());

    _socket.connect();

    _socket.onConnect((_) {
      print('Socket Connected: ${_socket.id}');
    });

    _socket.onDisconnect((_) {
      print('Socket Disconnected');
    });

    _socket.onError((data) => print('Socket Error: $data'));
  }

  // Hàm lắng nghe sự kiện cụ thể
  void onNewFloodReport(Function(dynamic) callback) {
    _socket.on('new_flood_report', (data) {
      print('New Flood Alert Received: $data');
      callback(data);
    });
  }

  void onWeatherUpdate(Function(dynamic) callback) {
    _socket.on('weather_update', (data) {
      print('Weather Update: $data');
      callback(data);
    });
  }

  void disconnect() {
    _socket.disconnect();
  }
}