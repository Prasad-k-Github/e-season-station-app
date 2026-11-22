import 'package:flutter/material.dart';

import '../api.dart';
import 'scan_screen.dart';

class LoginScreen extends StatefulWidget {
  final StationApi api;
  const LoginScreen({super.key, required this.api});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final TextEditingController _server = TextEditingController(text: widget.api.baseUrl);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _server.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.setBaseUrl(_server.text);
      await widget.api.login(_email.text, _password.text);
      if (!mounted) return;
      _password.clear();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ScanScreen(api: widget.api)),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Icon(Icons.qr_code_scanner_rounded, size: 64, color: Color(0xFF0A2558)),
                const SizedBox(height: 8),
                Text('E-Season Inspector',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Sign in with your station staff account',
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                  onSubmitted: (_) => _busy ? null : _login(),
                ),
                const SizedBox(height: 12),
                ExpansionTile(
                  title: const Text('Server address'),
                  tilePadding: EdgeInsets.zero,
                  children: [
                    TextField(
                      controller: _server,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        helperText: 'Emulator: http://10.0.2.2:3000. Real phone: http://<computer IP>:3000',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _login,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(_busy ? 'Signing in…' : 'Sign in'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
