import SwiftUI

struct PasswordPromptView: View {
    @Binding var isPresented: Bool
    var onAuthenticated: (String) -> Void
    
    @State private var password = ""
    @State private var shakeAttempt = 0
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 40))
                .foregroundColor(.red)
                .padding(.top, 20)
            
            Text("Lullaby Authorization")
                .font(.headline)
            
            Text("Enter the Master Password to continue.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 250)
                .onSubmit {
                    verifyPassword()
                }
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            HStack(spacing: 15) {
                Button("Cancel") {
                    isPresented = false
                    password = ""
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Unlock") {
                    verifyPassword()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding(.bottom, 20)
        }
        .frame(width: 320)
        .padding()
        .modifier(ShakeEffect(animatableData: CGFloat(shakeAttempt)))
    }
    
    private func verifyPassword() {
        if LullabyGuard.shared.verify(password) {
            isPresented = false
            onAuthenticated(password)
        } else {
            errorMessage = "Incorrect password."
            withAnimation(.default) {
                shakeAttempt += 1
            }
            password = ""
        }
    }
}

// Shake Animation Helper
struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 10 * sin(animatableData * .pi * 2), y: 0))
    }
}
