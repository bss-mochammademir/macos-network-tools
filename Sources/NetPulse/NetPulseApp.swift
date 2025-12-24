import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep the app running in the MenuBar even if the window is closed
        return false
    }
}

@main
struct NetPulseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    // Single source of truth for the entire app
    @StateObject private var networkMonitor = NetworkMonitor()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup {
            ContentView(networkMonitor: networkMonitor)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 400, height: 600)
        
        MenuBarExtra {
            Text("NetPulse: \(networkMonitor.currentPolicy.currentState.rawValue)")
            
            Divider()
            
            Button(networkMonitor.isMeetingModeEnabled ? "Stop Meeting Mode" : "Start Meeting Mode") {
                networkMonitor.toggleMeetingMode()
            }
            .keyboardShortcut("M")
            
            Button("Show Monitor") {
                NSApp.activate(ignoringOtherApps: true)
                // In macOS 13+, the first window opens automatically if not already open
            }
            .keyboardShortcut("S")
            
            Divider()
            
            Button("Quit NetPulse") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("Q")
        } label: {
            Image(systemName: networkMonitor.currentPolicy.currentState.icon)
        }
    }
}
