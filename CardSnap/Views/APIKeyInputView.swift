import SwiftUI

/// A premium Liquid Glass onboarding view to securely collect and save the user's Gemini API Key.
struct APIKeyInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var keyInput = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    @State private var hasSavedKey = false
    
    private let haptic = UINotificationFeedbackGenerator()
    
    var body: some View {
        ZStack {
            // ── Background Mesh ─────────────────────────────────────────────
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.08, blue: 0.05), // Deep emerald hues
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.02, green: 0.02, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Premium ambient forest-green orbs for depth
            Circle()
                .fill(Color.green.opacity(0.15))
                .frame(width: 400, height: 400)
                .blur(radius: 90)
                .offset(x: -150, y: -250)
            
            Circle()
                .fill(Color.teal.opacity(0.12))
                .frame(width: 350, height: 350)
                .blur(radius: 80)
                .offset(x: 150, y: 250)
            
            // ── Main Content Card ───────────────────────────────────────────
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    Spacer()
                        .frame(height: 40)
                    
                    // Animated key lock header icon
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.12))
                            .frame(width: 90, height: 90)
                            .blur(radius: 2)
                        
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 42))
                            .foregroundColor(.green)
                            .symbolEffect(.pulse)
                    }
                    .padding(.bottom, 8)
                    
                    // Welcome & Onboarding Header text
                    VStack(spacing: 8) {
                        Text("Welcome to CardSnap")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Privacy-First Card Scanning")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.green.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    
                    // Glassmorphic instructions card
                    GlassEffectContainer(spacing: 12) {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 16))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("100% Local & Privacy-First")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text("All OCR text recognition is executed natively on your device's Neural Engine. No images ever leave your device.")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.teal)
                                    .font(.system(size: 16))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Bring Your Own AI Key")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text("CardSnap parses raw card text into clean address book fields using Google's Gemini models via your own secure key.")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                        .padding(20)
                    }
                    .padding(.horizontal, 16)
                    
                    // Input Card
                    GlassEffectContainer(spacing: 16) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(hasSavedKey ? "MANAGE GEMINI API KEY" : "ENTER YOUR GEMINI API KEY")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.green)
                                .opacity(0.95)
                                .letterSpacing(1.2)
                            
                            // Secure input field
                            HStack {
                                Image(systemName: "key.fill")
                                    .foregroundColor(.green.opacity(0.7))
                                    .font(.system(size: 16))
                                
                                SecureField(hasSavedKey ? "••••••••••••••••••••" : "AIzaSy...", text: $keyInput)
                                    .foregroundColor(.white)
                                    .font(.system(size: 15, design: .monospaced))
                                    .disableAutocorrection(true)
                                    .autocapitalization(.none)
                            }
                            .padding(14)
                            .glassEffect(in: RoundedRectangle(cornerRadius: 12))
                            
                            if showingError {
                                Text(errorMessage)
                                    .font(.system(size: 12))
                                    .foregroundColor(.red.opacity(0.9))
                                    .transition(.opacity.combined(with: .slide))
                            }
                            
                            // Save Action Button
                            Button {
                                validateAndSave()
                            } label: {
                                HStack {
                                    Spacer()
                                    Text(hasSavedKey ? "Save Changes" : "Save & Get Started")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.black)
                                    Spacer()
                                }
                                .padding(.vertical, 14)
                                .background(Color.green)
                                .cornerRadius(12)
                            }
                            .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
                            
                            Divider()
                                .background(Color.white.opacity(0.15))
                            
                            // Redirect Button to Google AI Studio
                            Button {
                                if let url = URL(string: "https://aistudio.google.com/") {
                                    openURL(url)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.up.forward.app.fill")
                                        .font(.system(size: 15))
                                    Text("Get a Free Gemini Key from Google AI Studio")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(.green)
                                .padding(.vertical, 6)
                            }
                            
                            if hasSavedKey {
                                Divider()
                                    .background(Color.white.opacity(0.15))
                                
                                Button(role: .destructive) {
                                    KeychainHelper.shared.delete()
                                    keyInput = ""
                                    hasSavedKey = false
                                    haptic.notificationOccurred(.warning)
                                } label: {
                                    HStack {
                                        Image(systemName: "trash.fill")
                                            .font(.system(size: 14))
                                        Text("Delete Custom Key from Keychain")
                                            .font(.system(size: 13, weight: .bold))
                                    }
                                    .foregroundColor(.red.opacity(0.9))
                                    .padding(.vertical, 6)
                                }
                            }
                        }
                        .padding(20)
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer()
                        .frame(height: 20)
                }
            }
            .onAppear {
                checkSavedKey()
            }
        }
    }
    
    // MARK: - API Key Validation & Save
    private func checkSavedKey() {
        if let key = KeychainHelper.shared.read(), !key.isEmpty {
            hasSavedKey = true
            keyInput = key
        }
    }
    
    private func validateAndSave() {
        let trimmedKey = keyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedKey.isEmpty else {
            haptic.notificationOccurred(.error)
            errorMessage = "API key cannot be empty."
            withAnimation { showingError = true }
            return
        }
        
        guard trimmedKey.hasPrefix("AIzaSy") else {
            haptic.notificationOccurred(.error)
            errorMessage = "Invalid key format. Gemini keys must start with 'AIzaSy'."
            withAnimation { showingError = true }
            return
        }
        
        // Save securely to device Keychain
        KeychainHelper.shared.save(trimmedKey)
        haptic.notificationOccurred(.success)
        
        // Success: Dismiss key entry modal and return
        withAnimation {
            dismiss()
        }
    }
}

#Preview {
    APIKeyInputView()
}
