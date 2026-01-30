import 'dart:convert';
import 'package:http/http.dart' as http;

class AppConfig {
  final bool gradioServerRunning;
  final String gradioServerLink;
  final Map<String, String> ekadashiData;
  final String latestAppVersion;

  AppConfig({
    required this.gradioServerRunning,
    required this.gradioServerLink,
    required this.ekadashiData,
    required this.latestAppVersion,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    print('[AppConfig] Parsing config JSON: ' + json.toString());

    // Parse ekadashi_data if available, otherwise use empty map
    Map<String, String> ekadashiData = {};
    if (json['ekadashi_data'] != null) {
      final data = json['ekadashi_data'] as Map<String, dynamic>;
      ekadashiData = data.map((key, value) => MapEntry(key, value.toString()));
    }

    return AppConfig(
      gradioServerRunning: json['gradio_server_running'] ?? false,
      gradioServerLink: json['gradio_server_link'] ?? '',
      ekadashiData: ekadashiData,
      latestAppVersion: json['latest_app_version'] ?? '2.2.0',
    );
  }

  // Get list of dates from ekadashi_data keys
  List<String> get ekadashiDates => ekadashiData.keys.toList();
}

class ConfigService {
  static String get configUrl =>
      'https://raw.githubusercontent.com/AntarikshG/configuration/main/saintsapp.json?v=' +
      DateTime.now().millisecondsSinceEpoch.toString();

  static Future<AppConfig> fetchConfig() async {
    final url = configUrl;
    print('[ConfigService] Fetching config from: ' + url);
    final response = await http.get(Uri.parse(url));
    print('[ConfigService] Config HTTP status: ' + response.statusCode.toString());
    print('[ConfigService] Config file content: ' + response.body);
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return AppConfig.fromJson(jsonData);
    } else {
      print('[ConfigService] Failed to load config. Status: ' + response.statusCode.toString());
      throw Exception('Failed to load config');
    }
  }
}
