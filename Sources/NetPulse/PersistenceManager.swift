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

    func register() {
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
            
            // Load the agent
            shell("launchctl bootstrap gui/\(getuid()) \(plistURL.path)")
        } catch {
            print("❌ Persistence Error: \(error.localizedDescription)")
        }
    }

    func unregister() {
        if isRegistered() {
            shell("launchctl bootout gui/\(getuid()) \(plistURL.path)")
            try? FileManager.default.removeItem(at: plistURL)
            print("🗑️ Persistence: LaunchAgent removed.")
        }
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
}
