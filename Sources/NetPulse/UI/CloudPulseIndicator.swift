import SwiftUI

struct CloudPulseIndicator: View {
    let status: CloudStatus
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Animated Icon
            Image(systemName: status.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(status.color)
                .scaleEffect(shouldPulse ? (isAnimating ? 1.2 : 1.0) : 1.0)
                .opacity(shouldPulse ? (isAnimating ? 0.6 : 1.0) : 1.0)
                .animation(
                    shouldPulse ? Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .default,
                    value: isAnimating
                )
                .onAppear {
                    if shouldPulse {
                        isAnimating = true
                    }
                }
                .onChange(of: status) { newStatus in
                    isAnimating = shouldPulse
                }
            
            // Status Label
            Text(status.label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(status.color.opacity(0.1))
        )
    }
    
    private var shouldPulse: Bool {
        status == .syncing || status == .stale
    }
}
