import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class TrucoService extends ChangeNotifier {
  static const defaultUrl = String.fromEnvironment(
    'SERVER_URL',
    defaultValue: 'https://trucobr.up.railway.app',
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
  Timer? _ping, _retry, _spectatorTimer;
  String? spectatingCode;
  Map<String, dynamic>? spectatedRoom;
  bool _spectatorLoading = false;
  Future<void>? _refreshing;
  String _lastState = '';
  final Map<String, Future<Map<String, dynamic>>> _pendingReads = {};
  int _retryCount = 0;
  void applyState(Map<String, dynamic> value) {
    final signature = jsonEncode(value);
    if (signature == _lastState || disposed) return;
    _lastState = signature;
    data = value;
    notifyListeners();
  }

  void stopSpectating() {
    _spectatorTimer?.cancel();
    spectatingCode = null;
    spectatedRoom = null;
  }

  Future<void> spectate(String code) async {
    stopSpectating();
    final result = await request('api/rooms/spectate', {'code': code});
    spectatingCode = code;
    spectatedRoom = result;
    notifyListeners();
    _spectatorTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_spectatorLoading || disposed || spectatingCode != code) return;
      _spectatorLoading = true;
      try {
        final result = await request('api/rooms/spectate', {'code': code});
        if (!disposed && spectatingCode == code) {
          if (jsonEncode(spectatedRoom) != jsonEncode(result)) {
            spectatedRoom = result;
            notifyListeners();
          }
        }
      } catch (_) {
        // Keep the last public state and retry on the next tick.
      } finally {
        _spectatorLoading = false;
      }
    });
  }

  TrucoService({
    http.Client? client,
    this.url = defaultUrl,
    this.storage = const FlutterSecureStorage(),
  }) : client = client ?? http.Client();

  Future<Map<String, dynamic>> request(
    String path, [
    Map<String, dynamic>? body,
  ]) {
    if (body != null) return _request(path, body);
    final key = '$url|$token|$path';
    return _pendingReads.putIfAbsent(
      key,
      () => _request(path).whenComplete(() {
        _pendingReads.remove(key);
      }),
    );
  }

  Future<Map<String, dynamic>> _request(
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
            .timeout(const Duration(seconds: 20));
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

  Future<void> refresh() =>
      _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<void> _refresh() async {
    applyState(await request('api/me'));
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
        final wasConnected = connected;
        connected = true;
        _retryCount = 0;
        if (message['type'] == 'state') {
          applyState(Map<String, dynamic>.from(message['data'] as Map));
        } else if (!wasConnected && !disposed) {
          notifyListeners();
        }
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
    if (connected) {
      connected = false;
      notifyListeners();
    }
    _ping?.cancel();
    _retry?.cancel();
    _retry = Timer(Duration(seconds: (2 << _retryCount.clamp(0, 4))), connect);
    _retryCount++;
  }

  Future<void> logout() async {
    stopSpectating();
    await request('api/logout', {});
    token = null;
    data = {};
    _lastState = '';
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
    stopSpectating();
    _retry?.cancel();
    _ping?.cancel();
    _subscription?.cancel();
    _socket?.sink.close();
    client.close();
    super.dispose();
  }
}
