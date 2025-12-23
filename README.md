# NetPulse 🚀

NetPulse is a lightweight, premium macOS network monitoring tool inspired by GlassWire. It provides real-time visibility into your application's network traffic, including data usage (total) and current throughput (speed).

![NetPulse Preview](https://github.com/user-attachments/assets/placeholder-image) <!-- Add your screenshot here after pushing -->

## ✨ Features

- **Real-time Monitoring**: Automatically refreshes stats every 2 seconds using `nettop`.
- **Speed & Total Tracking**: Displays both cumulative data usage and real-time bandwidth (KB/s or MB/s).
- **Dynamic Sorting**: Toggle between **Top Total** (cumulative usage) and **Active Speed** (current activity).
- **Pro UI**: Modern macOS design with heat-map progress bars and dark mode support.
- **App Lifecycle**: Quits automatically when the window is closed.
- **Bundled App**: Includes a script to bundle the project into a native `.app` with a custom icon.

## 🚀 How to Run

### Requirements
- macOS 14.0 or later
- Swift 5.9 or later

### Option 1: Development
```bash
swift run
```

### Option 2: Build as Native App
```bash
chmod +x build_app.sh
./build_app.sh
```
The `NetPulse.app` will be created in the root directory. This bundle includes the `NetPulse.icns` icon.

## 🛠 Tech Stack
- **SwiftUI**: Modern declarative UI for macOS.
- **Nettop**: Low-level macOS utility for network statistics.
- **Combined**: For reactive data updates.

---
Developed with ❤️ by Emir.
