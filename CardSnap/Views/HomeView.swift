import SwiftUI
import PhotosUI

struct HomeView: View {
    @State private var showScanner = false
    @State private var showPhotoPicker = false
    @State private var pickedImage: UIImage? = nil
    @State private var croppedImage: UIImage? = nil
    @State private var showFlexCrop = false
    @State private var navigateToProcessing = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @Namespace private var glassNamespace

    var body: some View {
        NavigationStack {
            ZStack {
                // ── Background ─────────────────────────────────────────────
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

                // Ambient orbs
                Circle()
                    .fill(Color.purple.opacity(0.18))
                    .frame(width: 350, height: 350)
                    .blur(radius: 80)
                    .offset(x: -120, y: -200)

                Circle()
                    .fill(Color.cyan.opacity(0.12))
                    .frame(width: 300, height: 300)
                    .blur(radius: 70)
                    .offset(x: 130, y: 200)

                // ── Content ────────────────────────────────────────────────
                VStack(spacing: 0) {
                    Spacer()

                    // Hero card art
                    ZStack {
                        // Floating sample cards
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(
                                colors: [Color.purple.opacity(0.5), Color.blue.opacity(0.3)],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 280, height: 165)
                            .rotationEffect(.degrees(-8))
                            .offset(x: -20, y: 10)
                            .blur(radius: 1)

                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(
                                colors: [Color.teal.opacity(0.4), Color.indigo.opacity(0.5)],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 280, height: 165)
                            .rotationEffect(.degrees(4))
                            .offset(x: 15, y: -5)
                            .blur(radius: 0.5)

                        // Top card with glass
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .frame(width: 280, height: 165)
                            .overlay(
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.3))
                                            .frame(width: 40, height: 40)
                                            .overlay(Text("RS").font(.system(size: 14, weight: .bold)).foregroundColor(.white))
                                        Spacer()
                                        Image(systemName: "creditcard.fill")
                                            .foregroundColor(.white.opacity(0.4))
                                    }
                                    Spacer()
                                    Text("Rajan Sharma")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("VP Product • Acme Corp")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.7))
                                    Text("rajan@acme.com")
                                        .font(.system(size: 11))
                                        .foregroundColor(.cyan.opacity(0.8))
                                }
                                .padding(20)
                            )
                            .shadow(color: .black.opacity(0.4), radius: 30, x: 0, y: 15)
                    }
                    .padding(.bottom, 48)

                    // Title
                    VStack(spacing: 6) {
                        Text("CardSnap")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(colors: [.white, .white.opacity(0.7)],
                                               startPoint: .top, endPoint: .bottom)
                            )
                        Text("Scan a card. Save a contact.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.bottom, 48)

                    // ── Liquid Glass Action Buttons ─────────────────────────
                    GlassEffectContainer(spacing: 12) {
                        VStack(spacing: 12) {
                            // Primary: Scan with Camera (iOS only — no camera on Mac)
                            #if !targetEnvironment(macCatalyst)
                            Button {
                                showScanner = true
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: "camera.viewfinder")
                                        .font(.system(size: 22, weight: .semibold))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Scan with Camera")
                                            .font(.system(size: 17, weight: .semibold))
                                        Text("Point at any business card")
                                            .font(.system(size: 12))
                                            .opacity(0.7)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .opacity(0.5)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .foregroundColor(.white)
                            }
                            .glassEffect(in: RoundedRectangle(cornerRadius: 20))
                            .glassEffectID("scan", in: glassNamespace)
                            #endif

                            // Secondary: Import from Photos
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                HStack(spacing: 14) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 22, weight: .semibold))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Import from Photos")
                                            .font(.system(size: 17, weight: .semibold))
                                        Text("Choose an existing photo")
                                            .font(.system(size: 12))
                                            .opacity(0.7)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .opacity(0.5)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .foregroundColor(.white.opacity(0.85))
                            }
                            .glassEffect(in: RoundedRectangle(cornerRadius: 20))
                            .glassEffectID("photos", in: glassNamespace)
                        }
                        .padding(.horizontal, 24)
                    }

                    Spacer().frame(height: 60)
                }
            }
            .navigationDestination(isPresented: $navigateToProcessing) {
                if let image = croppedImage ?? pickedImage {
                    ProcessingView(cardImage: image)
                }
            }
            .fullScreenCover(isPresented: $showScanner) {
                ScannerView { scannedImage in
                    pickedImage = scannedImage
                    showScanner = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showFlexCrop = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showFlexCrop) {
                if let img = pickedImage {
                    FlexCropView(image: img) { cropped in
                        croppedImage = cropped
                        showFlexCrop = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            navigateToProcessing = true
                        }
                    } onCancel: {
                        showFlexCrop = false
                        pickedImage = nil
                    }
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let item = newItem else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        pickedImage = image
                        await MainActor.run { showFlexCrop = true }
                    }
                }
            }
        }
    }
}
