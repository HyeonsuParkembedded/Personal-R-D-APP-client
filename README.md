# LabPilot Client

Installable Flutter client for LabPilot.

## Targets

- Windows desktop
- Android phone
- Android tablet

## Current scope

- Installable Flutter shell for desktop and Android
- Responsive dashboard-style landing screen
- Configurable backend base URL field
- FastAPI health-check button

The client can launch even when the backend is not running. In that case, the health check simply reports a connection failure.

## Requirements

- Flutter SDK 3.41.4 or compatible stable release
- Windows desktop build tools for Windows builds
- Android SDK / Android Studio for Android builds

## Run

```bash
flutter pub get
flutter run -d windows
```

For Android emulator use the default backend base URL:

```text
http://10.0.2.2:8000
```

For Windows desktop use:

```text
http://127.0.0.1:8000
```

## Verification

```bash
flutter analyze
flutter test
```
