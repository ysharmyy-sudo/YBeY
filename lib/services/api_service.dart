import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ⚠️ Flutter Web / Desktop ke liye
  static const String baseUrl = "http://127.0.0.1:8000";

  // 🔹 Root check (optional)
  static Future<String> checkServer() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data["message"] ?? "Server running";
    } else {
      throw Exception("Server not responding");
    }
  }

  // 🔹 Statistics API
  static Future<Map<String, dynamic>> fetchStatistics() async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/statistics"),
      headers: {
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
        "Failed to load statistics (${response.statusCode})",
      );
    }
  }

  // 🔹 Example: Create visitor (future use)
  static Future<void> createVisitor({
    String? ipAddress,
    String? userAgent,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/visitors"),
      headers: {
        "Content-Type": "application/json",
      },
      body: json.encode({
        "ip_address": ipAddress,
        "user_agent": userAgent,
      }),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception("Failed to create visitor");
    }
  }
}
