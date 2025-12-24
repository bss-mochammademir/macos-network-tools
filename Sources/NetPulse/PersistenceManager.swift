import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()
    
    private let bundleId = "id.emiro.netpulse"
    private var plistURL: URL {
        let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        let launchAgentsURL = libraryURL.appendingPathComponent("LaunchAgents")
        return launchAgentsURL.appendingPathComponent("\(bundleId).plist")
    }
    
    private var appPath: String {
        return Bundle.main.bundlePath
    }
    
    private var executablePath: String {
        return Bundle.main.executablePath ?? "/Applications/NetPulse.app/Contents/MacOS/NetPulse"
    }

    func isRegistered() -> Bool {
        return FileManager.default.fileExists(atPath: plistURL.path)
    }

    func isHardened() -> Bool {
        let systemPlistPath = "/Library/LaunchDaemons/\(bundleId).plist"
        return FileManager.default.fileExists(atPath: systemPlistPath)
    }
    
    func isRunningAsRoot() -> Bool {
        return getuid() == 0
    }

    func register() {
        // Cleanup old legacy ID if it exists
        let oldBundleId = "com.emir.netpulse"
        let oldPlistURL = plistURL.deletingLastPathComponent().appendingPathComponent("\(oldBundleId).plist")
        if FileManager.default.fileExists(atPath: oldPlistURL.path) {
            shell("launchctl unload \(oldPlistURL.path) 2>/dev/null")
            try? FileManager.default.removeItem(at: oldPlistURL)
            print("🧹 Persistence: Cleaned up legacy agent \(oldBundleId)")
        }

        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(bundleId)</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(executablePath)</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <true/>
            <key>ProcessType</key>
            <string>Interactive</string>
        </dict>
        </plist>
        """
        
        do {
            // Ensure directory exists
            let directory = plistURL.deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: directory.path) {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            }
            
            try plistContent.write(to: plistURL, atomically: true, encoding: .utf8)
            print("✅ Persistence: LaunchAgent plist created at \(plistURL.path)")
            
            // Unload first if exists, then load -w (more robust for testing)
            shell("launchctl unload \(plistURL.path) 2>/dev/null")
            shell("launchctl load -w \(plistURL.path)")
        } catch {
            print("❌ Persistence Error: \(error.localizedDescription)")
        }
    }

    func unregister(password: String) -> Bool {
        guard LullabyGuard.shared.verify(password) else {
            print("🛑 Persistence: Lullaby authentication failed.")
            return false
        }
        if isRegistered() {
            shell("launchctl bootout gui/\(getuid()) \(plistURL.path)")
            try? FileManager.default.removeItem(at: plistURL)
            print("🗑️ Persistence: LaunchAgent removed.")
        }
        return true
    }

    @discardableResult
    private func shell(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.standardInput = nil

        try? task.run()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return output
    }

    @discardableResult
    func elevateToHardened() -> Bool {
        let bundlePath = Bundle.main.bundlePath
        
        // 1. Find the bundled script
        guard let scriptPath = Bundle.main.path(forResource: "harden_agent", ofType: "sh") else {
            print("❌ Error: harden_agent.sh not found in bundle resources.")
            return false
        }
        
        // 2. Identify the app bundle path (to pass to script for copying)
        let appPath = bundlePath
        
        print("🛡️ Attempting elevation with bundled script...")
        print("📜 Bundled Script: \(scriptPath)")
        print("📦 App Path: \(appPath)")

        let appleScript = "do shell script (quoted form of \"\(scriptPath)\" & \" \" & quoted form of \"\(appPath)\") with administrator privileges"
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", appleScript]
        
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            print("🚀 Elevation Output: \(output)")
            
            let success = process.terminationStatus == 0 && isHardened()
            print("🏁 Elevation Success: \(success)")
            return success
        } catch {
            print("❌ Elevation exception: \(error)")
            return false
        }
    }
    
    @discardableResult
    func relaxHardening(password: String) -> Bool {
        guard LullabyGuard.shared.verify(password) else {
            print("🛑 Persistence: Lullaby authentication failed.")
            return false
        }
        let bundleId = self.bundleId
        let tempScriptPath = "/tmp/relax_netpulse.sh"
        
        // Create a temporary script content
        let scriptContent = """
        #!/bin/bash
        launchctl unload /Library/LaunchDaemons/\(bundleId).plist 2>/dev/null || true
        rm -f /Library/LaunchDaemons/\(bundleId).plist
        rm -rf "/Library/Application Support/NetPulse"
        exit 0
        """
        
        do {
            try scriptContent.write(toFile: tempScriptPath, atomically: true, encoding: .utf8)
            // Make executable (chmod +x) - safe to do without sudo for /tmp file owned by user
            shell("chmod +x \(tempScriptPath)")
        } catch {
            print("❌ Failed to create temp script: \(error)")
            return false
        }
        
        // Execute the script via osascript
        let appleScript = "do shell script \"\(tempScriptPath)\" with administrator privileges"
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", appleScript]
        
        do {
            try process.run()
            process.waitUntilExit()
            
            // Clean up temp script
            try? FileManager.default.removeItem(atPath: tempScriptPath)
            
            return process.terminationStatus == 0 && !isHardened()
        } catch {
            print("❌ Relaxation failed: \(error)")
            try? FileManager.default.removeItem(atPath: tempScriptPath)
            return false
        }
    }

    private func quotedForm(_ string: String) -> String {
        return "quoted form of \"\(string.replacingOccurrences(of: "\"", with: "\\\""))\""
    }
}
