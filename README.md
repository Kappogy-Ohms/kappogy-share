# Kappogy Share 🚀

<div align="center">

**Ultra-Fast, Secure, End-to-End Encrypted Local File Sharing for Desktop & Mobile**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Android%20%7C%20iOS%20%7C%20macOS%20%7C%20Linux%20%7C%20Web-brightgreen.svg)]()
[![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?logo=flutter)](https://flutter.dev)

</div>

---

## 🌟 Overview

**Kappogy Share** is a modern, high-speed, and secure peer-to-peer file transfer desktop and mobile application. It enables seamless file and folder transfers across devices on your local Wi-Fi, Ethernet, or mobile hotspot without uploading anything to external cloud servers or relying on active internet connections.

---

## ✨ Key Features

- ⚡ **Blazing Fast Local TCP Transfer**: Stream files at full wire speed directly between devices with non-blocking socket pipelines.
- 🔐 **End-to-End Encryption**: Every transferred chunk is encrypted in transit using **ChaCha20-Poly1305 AEAD** with per-session key derivation.
- 🛡️ **SHA-256 Integrity Verification**: Automated cryptographic hashing validates that every received file matches the sender byte-for-byte.
- 📁 **Bulk Folder Sending & Archiving**: Add and inspect single or multiple directory trees simultaneously with automatic background compression.
- 📱 **Categorized Device Library**: Instantly browses your storage across 7 categories (`Recent`, `Photos`, `Videos`, `Audio`, `Apps`, `Contacts`, `Files`) with thumbnail previews.
- 📅 **Date Bucket Grouping & Batch Select**: Chronologically organized media grids with one-tap select-all circles on every date section.
- 📡 **Sonar Device Radar & mDNS Discovery**: Instant discovery using ZeroConf/Bonjour multicast DNS broadcast and proximity sonar radar.
- 🌐 **My Link (Zero-Install Web Sharing)**: Built-in local HTTP web server allowing any device (iOS, Mac, Linux, Smart TVs) to download or upload files directly via their web browser.
- 💬 **Encrypted In-Transfer Chat & Clipboard Sync**: Exchange real-time encrypted messages and synchronize clipboard text seamlessly during file transfers.
- 🎨 **Adaptive Material 3 Design**: Supports Light, Midnight Dark, and Pure AMOLED Black themes with Material You dynamic color accents.
- 🖥️ **Desktop Native Polish**: System tray minimization, custom window geometry management, and drag-and-drop file staging.

---

## 🛠 Supported Platforms

| Platform | Support Status | Notes |
| :--- | :---: | :--- |
| **Windows** | **Tier 1 (Official)** | Windows 10 & 11 (x64) with Setup Installer & Portable Zip |
| **Android** | **Tier 1 (Official)** | Android 5.0+ (API 21 to 35) APK / App Bundle |
| **iOS** | Supported | iOS 13+ with Local Network & Camera permissions |
| **macOS / Linux** | Supported | Native desktop builds available |
| **Any Browser** | **Web Client** | Direct browser download/upload via **My Link** hub |

---

## 💻 System Requirements

- **Windows**: Windows 10 (1809+) or Windows 11 (64-bit), 4 GB RAM, Wi-Fi or Ethernet adapter.
- **Android**: Android 5.0 (Lollipop) or newer.
- **Network**: Both devices connected to the same Wi-Fi network, local LAN switch, or mobile hotspot.

---

## 📥 Download & Installation

### Windows
1. Download the latest **`Kappogy-Share-Setup-1.0.0.exe`** from the [GitHub Releases](https://github.com/Kappogy-Ohms/kappogy-share/releases) page.
2. Run the installer and choose your installation options (Desktop icon, Start Menu shortcut).
3. Launch **Kappogy Share** from the Start Menu or Desktop.

> **Portable Option**: Download `Kappogy-Share-Portable-1.0.0.zip`, extract to any directory, and launch `kappogy_share.exe` directly without administrative privileges.

### Android
1. Download the latest **`Kappogy-Share-1.0.0.apk`** from [Releases](https://github.com/Kappogy-Ohms/kappogy-share/releases).
2. Open the `.apk` and allow installation from unknown sources if prompted.
3. Launch and grant storage/network permissions.

---

## 🏗 Build from Source

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.24.0 or higher)
- [Visual Studio 2022](https://visualstudio.microsoft.com/) with **Desktop development with C++** workload (Windows)
- [Inno Setup 6](https://jrsoftware.org/isdl.php) (for building the Windows installer)

### Build Steps

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/Kappogy-Ohms/kappogy-share.git
   cd kappogy-share
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run Code Generation**:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Build Windows Release**:
   ```bash
   flutter build windows --release
   ```

5. **Create Windows Setup Installer**:
   ```bash
   iscc setup.iss
   ```

6. **Build Android APK**:
   ```bash
   flutter build apk --release
   ```

---

## 🔐 Versioning & Releases

Current Version: **v1.0.0**  
Release Changelog: [Releases Page](https://github.com/Kappogy-Ohms/kappogy-share/releases)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Developer & Organization

Developed and maintained by **[Kappogy-Ohms](https://github.com/Kappogy-Ohms)**.
