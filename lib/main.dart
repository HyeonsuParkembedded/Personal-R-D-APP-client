import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const LabPilotApp());
}

class LabPilotApp extends StatelessWidget {
  const LabPilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF0F766E);

    return MaterialApp(
      title: 'LabPilot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
          surface: const Color(0xFFF5F2E9),
        ),
        scaffoldBackgroundColor: const Color(0xFFEDE7DA),
        useMaterial3: true,
      ),
      home: const LabPilotHomePage(),
    );
  }
}

class LabPilotHomePage extends StatefulWidget {
  const LabPilotHomePage({super.key});

  @override
  State<LabPilotHomePage> createState() => _LabPilotHomePageState();
}

class _LabPilotHomePageState extends State<LabPilotHomePage> {
  late final TextEditingController _baseUrlController;
  String _statusText = 'Not checked yet';
  bool _isHealthy = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController(text: _defaultBaseUrl());
    _pingBackend();
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    super.dispose();
  }

  String _defaultBaseUrl() {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  Future<void> _pingBackend() async {
    setState(() {
      _isChecking = true;
    });

    final uri = Uri.parse('${_baseUrlController.text}/health');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      final ok = response.statusCode == 200 && response.body.contains('ok');

      if (!mounted) {
        return;
      }

      setState(() {
        _isHealthy = ok;
        _statusText = ok
            ? 'Connected to FastAPI backend'
            : 'Backend responded with ${response.statusCode}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isHealthy = false;
        _statusText = 'Connection failed: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: _HeroPanel(
                            baseUrlController: _baseUrlController,
                            isChecking: _isChecking,
                            isHealthy: _isHealthy,
                            statusText: _statusText,
                            onPingPressed: _pingBackend,
                          ),
                        ),
                        const SizedBox(width: 20),
                        const Expanded(
                          flex: 5,
                          child: _WorkspaceOverview(),
                        ),
                      ],
                    )
                  : ListView(
                      children: [
                        _HeroPanel(
                          baseUrlController: _baseUrlController,
                          isChecking: _isChecking,
                          isHealthy: _isHealthy,
                          statusText: _statusText,
                          onPingPressed: _pingBackend,
                        ),
                        const SizedBox(height: 20),
                        const _WorkspaceOverview(),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.baseUrlController,
    required this.isChecking,
    required this.isHealthy,
    required this.statusText,
    required this.onPingPressed,
  });

  final TextEditingController baseUrlController;
  final bool isChecking;
  final bool isHealthy;
  final String statusText;
  final Future<void> Function() onPingPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF133E3A), Color(0xFF235B54), Color(0xFFB36A2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'LabPilot Installable Client',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'One client for desktop, tablet, and phone.',
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'This first Flutter shell focuses on installable access to your FastAPI backend. It gives you a shared workspace surface that can grow into project management, experiment logs, and hardware issue tracking.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: baseUrlController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Backend base URL',
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.84)),
              hintText: 'http://127.0.0.1:8000',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: isChecking ? null : onPingPressed,
                icon: isChecking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(isHealthy ? Icons.cloud_done : Icons.cloud_sync),
                label: Text(isChecking ? 'Checking' : 'Check backend'),
              ),
              _StatusChip(isHealthy: isHealthy, statusText: statusText),
            ],
          ),
          const SizedBox(height: 28),
          const Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricCard(label: 'Target devices', value: '3'),
              _MetricCard(label: 'API source', value: 'FastAPI'),
              _MetricCard(label: 'Storage', value: 'NAS'),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkspaceOverview extends StatelessWidget {
  const _WorkspaceOverview();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _SectionCard(
          title: 'Core modules',
          subtitle: 'Initial feature slices already aligned with the backend',
          items: [
            'Projects and status tracking',
            'Experiment logs with attachments',
            'Hardware issue management',
            'Repository links and synced timeline',
          ],
        ),
        SizedBox(height: 20),
        _SectionCard(
          title: 'Device strategy',
          subtitle: 'How this client adapts across screens',
          items: [
            'Windows desktop for full project overview',
            'Tablet for field review and quick logging',
            'Phone for capture-first updates and issue reporting',
          ],
        ),
        SizedBox(height: 20),
        _SectionCard(
          title: 'Next implementation targets',
          subtitle: 'Immediate steps to turn this shell into a working client',
          items: [
            'Add typed API client for FastAPI endpoints',
            'Build project list and project detail flows',
            'Add offline-safe draft entry forms for logs and issues',
          ],
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final String title;
  final String subtitle;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF5E645F),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.brightness_1, size: 10, color: Color(0xFF0F766E)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.84),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.isHealthy,
    required this.statusText,
  });

  final bool isHealthy;
  final String statusText;

  @override
  Widget build(BuildContext context) {
    final background = isHealthy
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFFDE68A);
    final foreground = isHealthy
        ? const Color(0xFF166534)
        : const Color(0xFF92400E);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
