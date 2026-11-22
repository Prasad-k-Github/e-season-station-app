import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../api.dart';
import '../offline_check.dart';
import 'login_screen.dart';

class ScanScreen extends StatefulWidget {
  final StationApi api;
  const ScanScreen({super.key, required this.api});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _checking = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<ScanResult> _verify(String token) async {
    try {
      return await widget.api.scan(token);
    } on ApiException catch (e) {
      if (!e.network) rethrow;
      // No internet: fall back to the signature check with the cached key.
      final key = await widget.api.cachedPublicKey();
      if (key == null) {
        throw const ApiException(
            'No internet and no saved public key. Sign in once while online.');
      }
      return checkOffline(token, key);
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_checking) return;
    final raw = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;
    _checking = true;
    await _controller.stop();

    ScanResult? result;
    String? error;
    try {
      result = await _verify(raw);
    } on ApiException catch (e) {
      if (e.unauthorized) {
        _signOut();
        return;
      }
      error = e.message;
    }

    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ResultScreen(api: widget.api, result: result, error: error),
    ));
    if (!mounted) return;
    _checking = false;
    await _controller.start();
  }

  void _signOut() {
    widget.api.signOut();
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginScreen(api: widget.api)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.api.staffName ?? 'Scan tickets'),
        actions: [
          IconButton(
            tooltip: 'Torch',
            icon: const Icon(Icons.flashlight_on_outlined),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            tooltip: 'Refresh offline key',
            icon: const Icon(Icons.vpn_key_outlined),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await widget.api.refreshPublicKey();
                messenger.showSnackBar(const SnackBar(content: Text('Offline key updated')));
              } on ApiException catch (e) {
                messenger.showSnackBar(SnackBar(content: Text(e.message)));
              }
            },
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Stack(children: [
        MobileScanner(controller: _controller, onDetect: _onDetect),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            color: Colors.black54,
            padding: const EdgeInsets.all(14),
            child: const Text('Point the camera at the passenger’s QR code',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
          ),
        ),
      ]),
    );
  }
}

class ResultScreen extends StatelessWidget {
  final StationApi api;
  final ScanResult? result;
  final String? error;
  const ResultScreen({super.key, required this.api, this.result, this.error});

  @override
  Widget build(BuildContext context) {
    final r = result;
    final Color color;
    final IconData icon;
    final String title;
    if (r == null) {
      color = Colors.orange.shade800;
      icon = Icons.error_outline;
      title = 'Could not check';
    } else if (r.isValid) {
      color = Colors.green.shade700;
      icon = Icons.check_circle_rounded;
      title = 'VALID';
    } else {
      color = Colors.red.shade700;
      icon = Icons.cancel_rounded;
      title = r.result.toUpperCase();
    }

    return Scaffold(
      backgroundColor: color,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 16),
            Icon(icon, color: Colors.white, size: 96),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(r?.message ?? error ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 20),
            if (r != null && r.holderName != null)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      if (r.photoPath != null && !r.offline) _Photo(api: api, path: r.photoPath!),
                      const SizedBox(height: 8),
                      Text(r.holderName!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text('${r.fromStation} → ${r.toStation}', style: const TextStyle(fontSize: 16)),
                      Text('${r.ticketClass} class'),
                      Text('Valid ${r.validFrom} to ${r.validTo}'),
                      if (r.offline)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('OFFLINE CHECK: no photo, revocation not checked',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w700)),
                        ),
                    ]),
                  ),
                ),
              )
            else
              const Spacer(),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: color),
              onPressed: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Scan next', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  final StationApi api;
  final String path;
  const _Photo({required this.api, required this.path});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: api.photo(path),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(height: 140, child: Center(child: CircularProgressIndicator()));
        }
        final bytes = snap.data;
        if (bytes == null) return const SizedBox.shrink();
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(bytes, height: 180, fit: BoxFit.cover),
        );
      },
    );
  }
}
