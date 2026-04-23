import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/api_constants.dart';
import 'token_service.dart';
import 'logger_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  
  bool _isConnected = false;
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;

    try {
      final token = await TokenService.getToken();
      if (token == null || token.isEmpty) {
        AppLogger.error(LogTags.payment, 'Socket connection failed: No token');
        return;
      }

      final wsUrl = ApiConstants.wsUrl;
      AppLogger.debug(LogTags.payment, 'Connecting to WebSocket: $wsUrl');

      _channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        headers: {
          'Authorization': 'Bearer $token',
        },
        pingInterval: const Duration(seconds: 25),
      );

      _subscription = _channel!.stream.listen(
        (data) {
          _handleMessage(data);
        },
        onError: (error) {
          AppLogger.error(LogTags.payment, 'WebSocket error: $error');
          _handleDisconnect();
        },
        onDone: () {
          AppLogger.debug(LogTags.payment, 'WebSocket connection closed');
          _handleDisconnect();
        },
      );

      _isConnected = true;
      // Start a ping timer if the server requires explicit payload-based pings
      // but usually web_socket_channel handles protocol pings if pingInterval is set.
    } catch (e) {
      AppLogger.error(LogTags.payment, 'WebSocket connection error: $e');
      _handleDisconnect();
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final Map<String, dynamic> message = jsonDecode(data);
      AppLogger.debug(LogTags.payment, 'WebSocket message received: ${message['type']}');
      
      if (message['type'] == 'ws.connected') {
        AppLogger.success(LogTags.payment, 'WebSocket handshake successful');
      }
      
      _eventController.add(message);
    } catch (e) {
      AppLogger.error(LogTags.payment, 'Error parsing WebSocket message: $e', data: {'raw': data});
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    _subscription?.cancel();
    _channel = null;
    
    // Attempt reconnection after 5 seconds
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      AppLogger.debug(LogTags.payment, 'Attempting to reconnect WebSocket...');
      connect();
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    AppLogger.debug(LogTags.payment, 'WebSocket disconnected manually');
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}
