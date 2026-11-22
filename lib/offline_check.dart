import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import 'api.dart';

/// Today's date in Sri Lanka (UTC+05:30) as YYYY-MM-DD.
String todayInSriLanka([DateTime? now]) {
  final d = (now ?? DateTime.now()).toUtc().add(const Duration(hours: 5, minutes: 30));
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Checks a ticket with the cached public key only (no internet). It proves
/// the ticket is genuine and within its dates, but cannot know if it was
/// revoked since it was issued.
ScanResult checkOffline(String token, String publicKeyPem, {DateTime? now}) {
  try {
    final jwt = JWT.verify(
      token,
      ECPublicKey(publicKeyPem),
      issuer: 'e-season',
      checkExpiresIn: false, // dates are checked below
    );
    final p = jwt.payload as Map<String, dynamic>;
    final from = '${p['vf']}';
    final to = '${p['vt']}';
    final today = todayInSriLanka(now);

    String result = 'valid';
    String message = 'Valid ticket (offline check, revocation not checked)';
    if (to.compareTo(today) < 0) {
      result = 'expired';
      message = 'Ticket has expired';
    } else if (from.compareTo(today) > 0) {
      result = 'invalid';
      message = 'Ticket is not valid yet';
    }
    return ScanResult(
      result: result,
      message: message,
      holderName: p['nm'] as String?,
      fromStation: p['fr'] as String?,
      toStation: p['to'] as String?,
      ticketClass: p['cls'] as String?,
      validFrom: from,
      validTo: to,
      offline: true,
    );
  } catch (_) {
    return const ScanResult(
      result: 'invalid',
      message: 'Not a genuine E-Season ticket',
      offline: true,
    );
  }
}
