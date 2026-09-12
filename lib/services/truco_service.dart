import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class TrucoService extends ChangeNotifier {
  static const defaultUrl = String.fromEnvironment(
    'SERVER_URL',
    defaultValue: 'https://aurora-z5xt.onrender.com',
  );
  final http.Client client;
  final FlutterSecureStorage storage;
  String url;
  String? token;
  Map<String, dynamic> data = {};
  bool connected = false;
  bool disposed = false;
  WebSocketChannel? _socket;
  StreamSubscription<dynamic>? _subscription;
  Timer? _ping, _retry;
  TrucoService({
    http.Client? client,
    this.url = defaultUrl,
    this.storage = const FlutterSecureStorage(),
  }) : client = client ?? http.Client();

  Future<Map<String, dynamic>> request(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final uri = Uri.parse('$url/$path');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final response =
        await (body == null
                ? client.get(uri, headers: headers)
                : client.post(uri, headers: headers, body: jsonEncode(body)))
            .timeout(const Duration(seconds: 60));
    Map<String, dynamic> result;
    try {
      result = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } catch (_) {
      throw Exception(
        'Não foi possível concluir a comunicação. Tente novamente em instantes.',
      );
    }
    if (response.statusCode >= 400) {
      throw Exception(
        result['detail'] ?? result['error'] ?? 'Falha no servidor.',
      );
    }
    return result;
  }

  Future<void> restore() async {
    token = await storage.read(key: 'truco_token');
    if (token != null) {
      try {
        await refresh();
        connect();
      } catch (_) {
        token = null;
        rethrow;
      }
    }
  }

  Future<void> login(String action, Map<String, dynamic> body) async {
    final response = await request('auth/$action', body);
    token = response.remove('token') as String;
    await storage.write(key: 'truco_token', value: token);
    data = response;
    notifyListeners();
    connect();
  }

  Future<void> refresh() async {
    data = await request('api/me');
    if (!disposed) notifyListeners();
  }

  void connect() {
    if (disposed || token == null) return;
    _retry?.cancel();
    _subscription?.cancel();
    _socket?.sink.close();
    final uri = Uri.parse(url)
        .replace(scheme: url.startsWith('https') ? 'wss' : 'ws', path: '/ws');
    _socket = WebSocketChannel.connect(uri);
    unawaited(
      _socket!.ready.catchError((Object error) {
        reconnect();
      }),
    );
    _socket!.sink.add(jsonEncode({'token': token}));
    _subscription = _socket!.stream.listen(
      (event) {
        final message = jsonDecode(event as String) as Map;
        connected = true;
        if (message['type'] == 'state') {
          data = Map<String, dynamic>.from(message['data'] as Map);
        }
        if (!disposed) notifyListeners();
      },
      onError: (Object _) => reconnect(),
      onDone: reconnect,
    );
    _ping?.cancel();
    _ping = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _socket?.sink.add('ping'),
    );
  }

  void reconnect() {
    if (disposed || token == null) return;
    connected = false;
    notifyListeners();
    _retry?.cancel();
    _retry = Timer(const Duration(seconds: 3), connect);
  }

  Future<void> logout() async {
    await request('api/logout', {});
    token = null;
    data = {};
    _retry?.cancel();
    _ping?.cancel();
    await _subscription?.cancel();
    await _socket?.sink.close();
    await storage.delete(key: 'truco_token');
    notifyListeners();
  }

  @override
  void dispose() {
    disposed = true;
    _retry?.cancel();
    _ping?.cancel();
    _subscription?.cancel();
    _socket?.sink.close();
    client.close();
    super.dispose();
  }
}
