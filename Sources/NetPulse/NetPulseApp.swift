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
        // HEADLESS MODE CHECK:
        // If we are running as Root (Daemon), do NOT show windows.
        // We only want the enforcement logic to run.
        let isRoot = (getuid() == 0)
        
        WindowGroup(id: "main") {
            if !isRoot {
                ContentView(networkMonitor: networkMonitor)
                    .alwaysOnTop()
            } else {
                // Daemon Mode: Empty View or specific status view
                // Ideally, WindowGroup shouldn't exist, but SwiftUI App lifecycle mandates a Scene.
                // We can use Settings scene only? Or EmptyView with hidden window.
                EmptyView()
                    .onAppear {
                        // In Daemon mode, we don't need the window.
                        // We rely on the app running in background.
                    }
            }
        }
        // Hide window completely if root
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: isRoot ? 0 : 400, height: isRoot ? 0 : 600)
        
        MenuBarExtra {
            Text("NetPulse: \(networkMonitor.currentPolicy.currentState.rawValue)")
            
            Divider()
            
            Button(networkMonitor.isMeetingModeEnabled ? "Stop Meeting Mode" : "Start Meeting Mode") {
                networkMonitor.toggleMeetingMode()
            }
            .keyboardShortcut("M")
            
            Button("Show Monitor") {
                openWindow(id: "main")
                
                // Fallback for cases where openWindow doesn't bring it to front
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" }) {
                        window.makeKeyAndOrderFront(nil)
                    }
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
            .keyboardShortcut("S")
            
            Divider()
            
            Button("Quit NetPulse") {
                // Request password via a standard macOS alert since MenuBarExtra doesn't support SwiftUI Alerts easily
                let alert = NSAlert()
                if networkMonitor.isHardened {
                    alert.messageText = "System Protection Active"
                    alert.informativeText = "NetPulse is currently HARDENED at the system level. Entering the master password will close this MenuBar icon, but the system daemon will remain active in the background for enforcement."
                } else {
                    alert.messageText = "Admin Authorization Required"
                    alert.informativeText = "Please enter the master password to quit NetPulse and disable persistence."
                }
                
                alert.alertStyle = .critical
                alert.addButton(withTitle: "Unlock")
                alert.addButton(withTitle: "Cancel")
                
                let input = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
                alert.accessoryView = input
                
                if alert.runModal() == .alertFirstButtonReturn {
                    if networkMonitor.verifyPassword(input.stringValue) {
                        if !networkMonitor.isHardened {
                            _ = PersistenceManager.shared.unregister(password: input.stringValue)
                        }
                        NSApplication.shared.terminate(nil)
                    }
                }
            }
            .keyboardShortcut("Q")
        } label: {
            Image(systemName: networkMonitor.currentPolicy.currentState.icon)
        }
    }
}
