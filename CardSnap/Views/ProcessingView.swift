import SwiftUI

/// Shows real-time OCR + Gemini AI parsing progress with full Liquid Glass UI.
struct ProcessingView: View {
    let cardImage: UIImage
    @Environment(\.dismiss) private var dismiss
    @State private var phase: ProcessingPhase = .ocr
    @State private var rawText: String = ""
    @State private var parsedContact: ParsedContact? = nil
    @State private var errorMessage: String? = nil
    @State private var navigateToPreview = false
    @Namespace private var glassNamespace
    private let haptic = UINotificationFeedbackGenerator()

    enum ProcessingPhase: CaseIterable {
        case ocr, gemini, done, error
        var label: String {
            switch self {
            case .ocr:    return "Reading card with Vision OCR..."
            case .gemini: return "AI parsing contact details..."
            case .done:   return "Contact ready!"
            case .error:  return "Something went wrong"
            }
        }
        var icon: String {
            switch self {
            case .ocr:    return "doc.text.viewfinder"
            case .gemini: return "sparkles"
            case .done:   return "checkmark.seal.fill"
            case .error:  return "exclamationmark.triangle.fill"
            }
        }
        var color: Color {
            switch self {
            case .ocr:    return .cyan
            case .gemini: return .purple
            case .done:   return .green
            case .error:  return .red
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.18),
                        Color(red: 0.10, green: 0.04, blue: 0.25),
                        Color(red: 0.02, green: 0.10, blue: 0.22)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Ambient
                Circle()
                    .fill(phase.color.opacity(0.15))
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
                    .animation(.easeInOut(duration: 1.2), value: phase)

                VStack(spacing: 32) {
                    // Card preview (small thumbnail)
                    Image(uiImage: cardImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 32)
                        .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)

                    // Glass status card
                    GlassEffectContainer(spacing: 16) {
                        VStack(spacing: 20) {
                            // Animated icon
                            ZStack {
                                Circle()
                                    .fill(phase.color.opacity(0.15))
                                    .frame(width: 80, height: 80)
                                Image(systemName: phase.icon)
                                    .font(.system(size: 32, weight: .semibold))
                                    .foregroundColor(phase.color)
                                    .symbolEffect(.pulse, isActive: phase == .ocr || phase == .gemini)
                            }
                            .animation(.spring(duration: 0.5), value: phase)

                            Text(phase.label)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .animation(.easeInOut, value: phase)

                            // Step indicators
                            HStack(spacing: 12) {
                                ForEach([ProcessingPhase.ocr, .gemini, .done], id: \.label) { step in
                                    let isActive = step == phase
                                    let isDone = isCompleted(step)
                                    Capsule()
                                        .fill(isDone ? Color.green : (isActive ? phase.color : Color.white.opacity(0.2)))
                                        .frame(width: isActive ? 48 : 28, height: 6)
                                        .animation(.spring(duration: 0.4), value: phase)
                                }
                            }

                            // OCR raw text preview
                            if !rawText.isEmpty && phase == .gemini {
                                Text(rawText)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.45))
                                    .lineLimit(4)
                                    .multilineTextAlignment(.leading)
                                    .padding(.horizontal, 4)
                            }

                            // Error handling
                            if let err = errorMessage {
                                Text(err)
                                    .font(.system(size: 13))
                                    .foregroundColor(.red.opacity(0.85))
                                    .multilineTextAlignment(.center)

                                Button("Try Again") { runPipeline() }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 10)
                                    .glassEffect(in: Capsule())
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(28)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationDestination(isPresented: $navigateToPreview) {
                if let contact = parsedContact {
                    ContactPreviewView(contact: contact, cardImage: cardImage)
                }
            }
            .navigationBarBackButtonHidden(phase == .ocr || phase == .gemini)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if phase == .error {
                        Button("Cancel") { dismiss() }
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .task { runPipeline() }
        }
    }

    private func isCompleted(_ step: ProcessingPhase) -> Bool {
        let order: [ProcessingPhase] = [.ocr, .gemini, .done]
        guard let stepIdx = order.firstIndex(of: step),
              let phaseIdx = order.firstIndex(of: phase) else { return false }
        return phaseIdx > stepIdx
    }

    private func runPipeline() {
        errorMessage = nil
        Task {
            do {
                // Step 1: On-device OCR
                await MainActor.run { phase = .ocr }
                let text = try await OCRService.shared.extractText(from: cardImage)
                await MainActor.run { rawText = text }

                // Step 2: Gemini AI waterfall parsing
                await MainActor.run { phase = .gemini }
                var contact = try await GeminiService.shared.parseBusinessCard(rawText: text)
                
                // Automagically set the cropped card image as the contact's profile photo
                contact.photo = cardImage

                // Step 3: Done
                await MainActor.run {
                    parsedContact = contact
                    phase = .done
                    haptic.notificationOccurred(.success)
                }
                try await Task.sleep(for: .milliseconds(600))
                await MainActor.run { navigateToPreview = true }

            } catch {
                await MainActor.run {
                    phase = .error
                    errorMessage = error.localizedDescription
                    haptic.notificationOccurred(.error)
                }
            }
        }
    }
}
