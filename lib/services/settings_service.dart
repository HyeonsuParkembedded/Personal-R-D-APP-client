import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const _keyGithub = 'github_token';
  static const _keyGitlab = 'gitlab_token';
  static const _keyBackendUrl = 'backend_url';

  Future<String?> getBackendUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBackendUrl);
  }

  Future<void> saveBackendUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url.trim().isEmpty) {
      await prefs.remove(_keyBackendUrl);
    } else {
      await prefs.setString(_keyBackendUrl, url.trim());
    }
  }

  Future<String?> getGithubToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGithub);
  }

  Future<String?> getGitlabToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGitlab);
  }

  Future<void> saveGithubToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token.trim().isEmpty) {
      await prefs.remove(_keyGithub);
    } else {
      await prefs.setString(_keyGithub, token.trim());
    }
  }

  Future<void> saveGitlabToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token.trim().isEmpty) {
      await prefs.remove(_keyGitlab);
    } else {
      await prefs.setString(_keyGitlab, token.trim());
    }
  }

  /// Returns true if at least one token is saved.
  Future<bool> hasAnyToken() async {
    final github = await getGithubToken();
    final gitlab = await getGitlabToken();
    return (github != null && github.isNotEmpty) ||
        (gitlab != null && gitlab.isNotEmpty);
  }
}
