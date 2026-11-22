import 'package:e_season_station/offline_check.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Sri Lanka date rolls over at 18:30 UTC', () {
    expect(todayInSriLanka(DateTime.utc(2026, 11, 23, 18, 29)), '2026-11-23');
    expect(todayInSriLanka(DateTime.utc(2026, 11, 23, 18, 30)), '2026-11-24');
  });

  test('a garbage token is reported as not genuine', () {
    final r = checkOffline('not-a-token', '-----BEGIN PUBLIC KEY-----\nabc\n-----END PUBLIC KEY-----');
    expect(r.result, 'invalid');
    expect(r.offline, true);
  });
}
