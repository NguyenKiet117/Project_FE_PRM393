import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

/// Gọi REST API của backend Spring Boot. Mọi response có dạng
/// { success, message, data, timestamp } -> hàm trả về phần `data`.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? client,
    // Render gói miễn phí "ngủ" khi lâu không có request -> lần đầu có thể mất ~1 phút.
    this.timeout = const Duration(seconds: 60),
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final Duration timeout;
  final http.Client _client;
  String? token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path, [Map<String, String>? query]) => Uri.parse('$baseUrl$path')
      .replace(queryParameters: (query == null || query.isEmpty) ? null : query);

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send(() => _client.get(_uri(path, query), headers: _headers));

  Future<dynamic> post(String path, {Object? body}) => _send(() =>
      _client.post(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));

  Future<dynamic> put(String path, {Object? body}) => _send(() =>
      _client.put(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));

  Future<dynamic> delete(String path) =>
      _send(() => _client.delete(_uri(path), headers: _headers));

  /// Upload file (multipart/form-data), ví dụ POST /api/quizzes/import.
  Future<dynamic> postMultipart(
    String path, {
    required String fileField,
    required List<int> bytes,
    required String filename,
    Map<String, String> fields = const {},
  }) =>
      _send(() async {
        final req = http.MultipartRequest('POST', _uri(path))
          ..headers.addAll({
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          })
          ..fields.addAll(fields)
          ..files.add(http.MultipartFile.fromBytes(fileField, bytes, filename: filename));
        return http.Response.fromStream(await _client.send(req));
      });

  Future<dynamic> _send(Future<http.Response> Function() call) async {
    try {
      final res = await call().timeout(timeout);
      return _unwrap(res);
    } on TimeoutException {
      throw const ApiException(
          'Máy chủ phản hồi quá chậm (có thể đang khởi động). Thử lại sau ít phút.');
    } on SocketException {
      throw const ApiException('Không kết nối được máy chủ. Kiểm tra mạng.');
    } on http.ClientException {
      throw const ApiException('Không kết nối được máy chủ. Kiểm tra mạng.');
    }
  }

  dynamic _unwrap(http.Response res) {
    Map<String, dynamic>? json;
    try {
      final d = jsonDecode(utf8.decode(res.bodyBytes));
      if (d is Map<String, dynamic>) json = d;
    } catch (_) {}
    final okHttp = res.statusCode >= 200 && res.statusCode < 300;
    if (!okHttp || json?['success'] == false) {
      throw ApiException(
        (json?['message'] as String?) ?? 'Lỗi máy chủ (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    return json?['data'];
  }
}
