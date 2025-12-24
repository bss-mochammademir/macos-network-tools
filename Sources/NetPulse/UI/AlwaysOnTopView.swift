import SwiftUI
import AppKit

struct AlwaysOnTopView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.level = .floating
                window.makeKeyAndOrderFront(nil)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

extension View {
    func alwaysOnTop() -> some View {
        self.background(AlwaysOnTopView().frame(width: 0, height: 0))
    }
}
