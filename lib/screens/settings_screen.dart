import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _githubController = TextEditingController();
  final _gitlabController = TextEditingController();
  final _backendController = TextEditingController();
  final _settingsService = SettingsService();

  bool _githubObscure = true;
  bool _gitlabObscure = true;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadTokens();
  }

  Future<void> _loadTokens() async {
    final github = await _settingsService.getGithubToken();
    final gitlab = await _settingsService.getGitlabToken();
    final backend = await _settingsService.getBackendUrl();
    setState(() {
      _githubController.text = github ?? '';
      _gitlabController.text = gitlab ?? '';
      _backendController.text = backend ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await _settingsService.saveGithubToken(_githubController.text);
    await _settingsService.saveGitlabToken(_gitlabController.text);
    await _settingsService.saveBackendUrl(_backendController.text);
    
    // 즉시 ApiClient 에 반영
    ApiClient().setBaseUrl(_backendController.text);
    
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 토큰이 저장되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // return true so list screen refreshes banner
    }
  }

  @override
  void dispose() {
    _githubController.dispose();
    _gitlabController.dispose();
    _backendController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API 토큰 설정'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---------- Info banner ----------
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '토큰은 이 기기에만 안전하게 저장되며, 서버로 전송되지 않습니다.\n'
                              'GitHub/GitLab 저장소를 연동하거나 커밋/브랜치 정보를 불러올 때 사용됩니다.',
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ---------- Backend URL ----------
                    _sectionLabel(
                      icon: Icons.dns,
                      label: 'LabPilot Backend Server URL',
                      hint: '빈칸으로 두면 기본 로컬 주소(127.0.0.1 또는 10.0.2.2)를 사용합니다.\n예: http://192.168.1.100:8000',
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _backendController,
                      decoration: InputDecoration(
                        hintText: 'http://서버주소:8000',
                        prefixIcon: const Icon(Icons.link),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ---------- GitHub ----------
                    _sectionLabel(
                      icon: Icons.code,
                      label: 'GitHub Personal Access Token',
                      hint: 'github.com → Settings → Developer settings → Personal access tokens',
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _githubController,
                      obscureText: _githubObscure,
                      decoration: InputDecoration(
                        hintText: 'ghp_xxxxxxxxxxxxxxxxxxxx',
                        prefixIcon: const Icon(Icons.key),
                        suffixIcon: IconButton(
                          icon: Icon(_githubObscure
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _githubObscure = !_githubObscure),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ---------- GitLab ----------
                    _sectionLabel(
                      icon: Icons.merge_type,
                      label: 'GitLab Personal Access Token',
                      hint: 'gitlab.com → User Settings → Access Tokens',
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _gitlabController,
                      obscureText: _gitlabObscure,
                      decoration: InputDecoration(
                        hintText: 'glpat-xxxxxxxxxxxxxxxxxxxx',
                        prefixIcon: const Icon(Icons.key),
                        suffixIcon: IconButton(
                          icon: Icon(_gitlabObscure
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _gitlabObscure = !_gitlabObscure),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ---------- Save ----------
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save),
                        label: Text(_saving ? '저장 중...' : '저장하기'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionLabel({
    required IconData icon,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          hint,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
