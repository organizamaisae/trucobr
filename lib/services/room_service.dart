import 'dart:convert';

import 'package:http/http.dart' as http;

class RoomService {
  static const serverUrl = String.fromEnvironment(
    'https://aurora-z5xt.onrender.com',
  );
  static final Map<String, Map<String, dynamic>> _localRooms = {};
  Future<Map<String, dynamic>> create(
    String name,
    int capacity,
    bool private,
  ) async {
    if (serverUrl.isEmpty) {
      final code = DateTime.now().microsecondsSinceEpoch
          .toRadixString(36)
          .toUpperCase();
      final room = <String, dynamic>{
        'code': code.substring(code.length - 6),
        'name': name,
        'capacity': capacity,
        'private': private,
      };
      _localRooms[room['code'] as String] = room;
      return room;
    }
    return _request('/rooms', {
      'name': name,
      'capacity': capacity,
      'private': private,
    });
  }

  Future<Map<String, dynamic>> join(
    String code, {
    String playerName = 'Jogador',
  }) async {
    if (serverUrl.isEmpty) {
      final room = _localRooms[code];
      if (room == null) {
        throw Exception(
          'Sala não encontrada neste dispositivo. Configure o servidor para compartilhar salas.',
        );
      }
      return room;
    }
    return _request('/rooms/$code/join', {'name': playerName});
  }

  Future<Map<String, dynamic>> _request(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .post(
          Uri.parse('${serverUrl.replaceFirst(RegExp(r'/$'), '')}$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Falha no servidor');
    }
    return data;
  }
}
