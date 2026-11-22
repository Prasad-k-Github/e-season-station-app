# E-Season Station (inspector) app

Flutter app for station staff: sign in, scan a passenger's season-ticket QR code, see **VALID / EXPIRED / REVOKED / INVALID** with the holder's name, route and photo.

- **Online:** the backend checks signature, dates and revocation, and logs the scan.
- **Offline:** if the server can't be reached, the app verifies the ES256 signature and dates with the public key saved at sign-in. It cannot know about revoked tickets, and shows no photo. The result screen says so.

## First-time setup
This repo holds the Dart code only. Generate the platform folders once:

```
flutter create . --project-name e_season_station --org lk.eseason --platforms android,ios
flutter pub get
```

**iOS only:** add to `ios/Runner/Info.plist`:
```
<key>NSCameraUsageDescription</key>
<string>The camera is used to scan season ticket QR codes.</string>
```
Android needs nothing extra (the scanner plugin declares the camera permission). If you test on an emulator, use `minSdkVersion 23` or higher (`android/app/build.gradle`: `minSdk = 23`).

## Run
```
flutter run
```
On the sign-in screen, open **Server address**:
- Android emulator: `http://10.0.2.2:3000`
- Real phone (same Wi-Fi): `http://<your computer's IP>:3000`

Sign in with a station staff account (create it in the admin console: Staff accounts → role "Station staff").

## Demo
1. Passenger app: apply, pay (sandbox) → My Pass shows the QR.
2. This app: scan it → green VALID.
3. Turn the server off and scan again → "OFFLINE CHECK" result.
