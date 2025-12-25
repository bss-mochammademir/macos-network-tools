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
        let isRoot = (getuid() == 0)
        
        // 1. Dashboard Window (Simple View) - Singleton via Window scene
        Window("NetPulse Dashboard", id: "main") {
            if !isRoot {
                SimpleView(networkMonitor: networkMonitor)
                    .alwaysOnTop()
                    .onAppear {
                        applyWindowStyling(id: "main", fixedSize: CGSize(width: 400, height: 500))
                    }
            } else {
                EmptyView()
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: isRoot ? 0 : 400, height: isRoot ? 0 : 500)

        // 2. Technical Monitor Window - Singleton via Window scene
        Window("Technical Monitor", id: "technical") {
            if !isRoot {
                TechnicalView(networkMonitor: networkMonitor)
                    .alwaysOnTop()
                    .onAppear {
                        applyWindowStyling(id: "technical", fixedSize: CGSize(width: 400, height: 600))
                    }
            } else {
                EmptyView()
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: isRoot ? 0 : 400, height: isRoot ? 0 : 600)
        
        MenuBarExtra {
            Text("NetPulse: \(networkMonitor.currentPolicy.currentState.rawValue)")
            
            Divider()
            
            Button("Show Dashboard") {
                openWindow(id: "main")
                ensureWindowFront(id: "main", fixedSize: CGSize(width: 400, height: 500))
            }
            .keyboardShortcut("D")

            Button("Open Technical Monitor") {
                openWindow(id: "technical")
                ensureWindowFront(id: "technical", fixedSize: CGSize(width: 400, height: 600))
            }
            .keyboardShortcut("T")
            
            Divider()

            Button(networkMonitor.isMeetingModeEnabled ? "Stop Meeting Mode" : "Start Meeting Mode") {
                networkMonitor.toggleMeetingMode()
            }
            .keyboardShortcut("M")
            
            Divider()
            
            Button("Quit NetPulse") {
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

    private func applyWindowStyling(id: String, fixedSize: CGSize) {
        // Delay to ensure window is created and available in NSApp.windows
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == id }) {
                if id == "main" {
                    // Dashboard is fixed size, only close button
                    window.styleMask.remove([.resizable, .miniaturizable])
                    window.standardWindowButton(.zoomButton)?.isHidden = true
                    window.standardWindowButton(.miniaturizeButton)?.isHidden = true
                    window.setContentSize(fixedSize)
                } else {
                    // Technical Monitor is standard (resizable, minimizable, maximizable)
                    window.styleMask.insert([.resizable, .miniaturizable])
                    window.standardWindowButton(.zoomButton)?.isHidden = false
                    window.standardWindowButton(.miniaturizeButton)?.isHidden = false
                    // No fixed size enforcement for technical view
                }
            }
        }
    }

    private func ensureWindowFront(id: String, fixedSize: CGSize) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == id }) {
                if id == "main" {
                    // Re-apply styling for main window
                    window.styleMask.remove([.resizable, .miniaturizable])
                    window.standardWindowButton(.zoomButton)?.isHidden = true
                    window.standardWindowButton(.miniaturizeButton)?.isHidden = true
                    window.setContentSize(fixedSize)
                }
                
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}
