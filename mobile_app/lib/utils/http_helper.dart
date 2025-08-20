import 'package:http/http.dart' as http;

class HttpHelper {
  static Map<String, String> getHeaders({
    String? authToken,
    Map<String, String>? additionalHeaders,
  }) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true', // Bypass ngrok warning
    };

    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  static Future<http.Response> get(
    String url, {
    String? authToken,
    Map<String, String>? additionalHeaders,
  }) async {
    return await http.get(
      Uri.parse(url),
      headers: getHeaders(
        authToken: authToken,
        additionalHeaders: additionalHeaders,
      ),
    );
  }

  static Future<http.Response> post(
    String url, {
    String? authToken,
    Map<String, String>? additionalHeaders,
    Object? body,
  }) async {
    return await http.post(
      Uri.parse(url),
      headers: getHeaders(
        authToken: authToken,
        additionalHeaders: additionalHeaders,
      ),
      body: body,
    );
  }

  static Future<http.Response> put(
    String url, {
    String? authToken,
    Map<String, String>? additionalHeaders,
    Object? body,
  }) async {
    return await http.put(
      Uri.parse(url),
      headers: getHeaders(
        authToken: authToken,
        additionalHeaders: additionalHeaders,
      ),
      body: body,
    );
  }

  static Future<http.Response> delete(
    String url, {
    String? authToken,
    Map<String, String>? additionalHeaders,
  }) async {
    return await http.delete(
      Uri.parse(url),
      headers: getHeaders(
        authToken: authToken,
        additionalHeaders: additionalHeaders,
      ),
    );
  }
}