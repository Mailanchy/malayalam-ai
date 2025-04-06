import 'dart:io';


class WebSocketManager {
  // The WebSocket server URL.
  final String url = "ws://137.184.6.3/chat";
  WebSocket? _socket;

  /// Connects to the WebSocket.
  /// Call this function on initialization.
  Future<void> connect() async {
    try {
      _socket = await WebSocket.connect(url);
      print('Connected to WebSocket: $url');
    } catch (e) {
      print('Error connecting to WebSocket: $e');
    }
  }

  /// Sends a text message over the WebSocket.
  void sendText(String message) {
    if (_socket != null && _socket!.readyState == WebSocket.open) {
      _socket!.add(message);
      print('Sent: $message');
    } else {
      print("WebSocket is not connected.");
    }
  }

  /// Starts listening for incoming messages.
  /// The [onMessage] callback is triggered whenever a new message is received.
  void listen(void Function(dynamic message) onMessage) {
    if (_socket != null) {
      _socket!.listen(
            (dynamic message) {
          onMessage(message);
        },
        onError: (error) {
          print('WebSocket error: $error');
        },
        onDone: () {
          print('WebSocket connection closed.');
        },
      );
    } else {
      print("WebSocket is not connected.");
    }
  }

  /// Disconnects from the WebSocket.
  Future<void> disconnect() async {
    if (_socket != null) {
      await _socket!.close();
      _socket = null;
      print("WebSocket disconnected.");
    }
  }
}
