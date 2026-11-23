import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api.dart';
import '../theme.dart';
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
      backgroundColor: AppColors.deepViolet,
      body: Column(children: [
        Stack(children: [
          Positioned.fill(child: Image.asset('assets/images/background02.jpg', fit: BoxFit.cover)),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.deepViolet.withValues(alpha: 0.60),
                    AppColors.deepViolet.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
              child: Row(children: [
                Image.asset('assets/images/train_logo.png', height: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('E-Season Inspector',
                        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text('Sign in with your station staff account',
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.white60)),
                  ]),
                ),
              ]),
            ),
          ),
        ]),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: fieldDec('E-mail', Icons.email_outlined),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: fieldDec('Password', Icons.lock_outline_rounded),
                  onSubmitted: (_) => _busy ? null : _login(),
                ),
                const SizedBox(height: 8),
                ExpansionTile(
                  title: const Text('Server address'),
                  tilePadding: EdgeInsets.zero,
                  shape: const Border(),
                  collapsedShape: const Border(),
                  children: [
                    TextField(
                      controller: _server,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      decoration: fieldDec('Server', Icons.dns_outlined,
                          helper: 'Emulator: http://10.0.2.2:3000. Real phone: http://<computer IP>:3000'),
                    ),
                  ],
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_error!, style: const TextStyle(color: AppColors.red)),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _login,
                  child: Text(_busy ? 'Signing in…' : 'Sign in'),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
