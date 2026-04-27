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
  int _reconnectAttempts = 0;
  final int _maxReconnectDelay = 30; // Max 30 seconds
  
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;
  Stream<bool> get connectionStatusStream => _connectionController.stream;
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
          _isConnected = false;
          _handleDisconnect();
        },
        onDone: () {
          AppLogger.debug(LogTags.payment, 'WebSocket connection closed');
          _isConnected = false;
          _connectionController.add(false);
          _handleDisconnect();
        },
      );

      // We don't set _isConnected = true yet. 
      // We wait for the 'ws.connected' handshake or at least for the stream to open.
    } catch (e) {
      AppLogger.error(LogTags.payment, 'WebSocket connection error: $e');
      _isConnected = false;
      _handleDisconnect();
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final Map<String, dynamic> message = jsonDecode(data);
      AppLogger.debug(LogTags.payment, 'WebSocket message received: ${message['type']}');
      
      if (message['type'] == 'ws.connected') {
        AppLogger.success(LogTags.payment, 'WebSocket handshake successful');
        _isConnected = true;
        _connectionController.add(true);
        _reconnectAttempts = 0; // Reset attempts on successful handshake
      }
      
      _eventController.add(message);
    } catch (e) {
      AppLogger.error(LogTags.payment, 'Error parsing WebSocket message: $e', data: {'raw': data});
    }
  }

  void _handleDisconnect() {
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    
    _reconnectTimer?.cancel();
    
    // Exponential backoff
    final delay = (_reconnectAttempts < 6) 
        ? (1 << _reconnectAttempts) // 1, 2, 4, 8, 16, 32...
        : _maxReconnectDelay;
    
    _reconnectAttempts++;
    
    AppLogger.debug(LogTags.payment, 'WebSocket scheduled reconnection in $delay seconds (attempt $_reconnectAttempts)');
    
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      if (!_isConnected) {
        AppLogger.debug(LogTags.payment, 'Attempting to reconnect WebSocket...');
        connect();
      }
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _reconnectAttempts = 0;
    AppLogger.debug(LogTags.payment, 'WebSocket disconnected manually');
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode(message));
        AppLogger.debug(LogTags.payment, 'WebSocket message sent: ${message['type'] ?? 'unknown'}');
      } catch (e) {
        AppLogger.error(LogTags.payment, 'Error sending WebSocket message: $e');
      }
    } else {
      AppLogger.warning(LogTags.payment, 'Cannot send WebSocket message: Not connected');
    }
  }

  void dispose() {
    disconnect();
    _eventController.close();
    _connectionController.close();
  }
}
