# ✅ Phase 1: Core Network Monitoring

**Status**: Completed
**Focus**: Foundation & Data Extraction

The objective of Phase 1 was to establish a reliable foundation for network monitoring on macOS without requiring third-party libraries or kernel extensions.

## Key Accomplishments
- **Swift Project Setup**: Initialized the project as a Swift Executable with a SwiftUI interface for macOS 14.0+.
- **`nettop` Engine**: Implemented a parser for the native macOS `nettop` command in "logging" mode (`nettop -l 1 -L -1`).
- **Real-time Parsing**: Created logic to extract:
    - Process Name
    - Bytes In / Bytes Out (per process)
    - Global ingress/egress totals.
- **Speed Calculation**: Implemented differential speed calculation (delta between snapshots) to provide real-time bytes-per-second metrics.
- **`NetworkMonitor` Class**: Established the core `@ObservableObject` that drives the entire application state.

## Technical Details
- **Binary**: `/usr/bin/nettop`
- **Signal Handling**: Basic lifecycle management for the background `nettop` process.
- **Concurrency**: Used `Process` and `FileHandle` to pipe output into the Swift environment.
