# 📱 OpenAamps — Flutter Mobile Application for Android & pi-aamps

OpenAamps is a modern, open-source Android Mobile Music Application built with **Flutter 3.44+** and **Material Design 3** (inspired by **OpenTune** and **ArchiveTune**).

It acts as both a standalone phone music player and a remote control hub for **pi-aamps** Raspberry Pi audio systems.

---

## 🌟 Key Features

- **📱 Standalone Phone Music Player**: Stream YouTube Music, play local device audio, and download `.mp3` tracks directly to phone storage without needing a Raspberry Pi connection.
- **📻 pi-aamps Remote Control Hub**: Connect to Raspberry Pi 3B+ (`http://<pi_ip>:8000`), control ALSA PCM hardware volume, 10-band equalizer presets (`Bass Boost`, `Vocal`, `Rock`, `Jazz`), and toggle Bluetooth Receiver mode ON/OFF.
- **🔀 1-Tap Output Switcher**: Instantly switch output target between `📱 This Phone Speaker` and `📻 pi-aamps (Raspberry Pi)` directly from the bottom mini-player bar.
- **🎨 Material 3 Glassmorphism UI**: Dynamic dark glassmorphism design with high-resolution artwork support, progress bars, and bottom navigation.

---

## 🛠️ Project Structure

```
mobile/
├── android/            # Android native configuration & AndroidManifest.xml
├── ios/                # iOS project configuration
├── lib/
│   ├── main.dart       # App entry point & main navigation screen
│   ├── models/         # Track & PiState data models
│   ├── services/       # Audio player, YouTube stream extractor, and pi-aamps REST/WebSocket services
│   ├── views/          # HomeView, SearchView, PlayerView, PiHubView, LibraryView
│   └── widgets/        # NowPlayingBar, OutputTargetModal
└── pubspec.yaml        # Flutter package dependencies
```

---

## 🚀 Building & Running

### Requirements
- **Flutter SDK** >= 3.12.2
- **Dart SDK** >= 3.12.2
- **Android SDK** (for APK generation)

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run Code Analysis
```bash
flutter analyze
```

### 3. Build Android Release APK
```bash
flutter build apk --release
```
The output APK will be placed at:
`mobile/build/app/outputs/flutter-apk/app-release.apk`

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit Pull Requests or file Issues.
