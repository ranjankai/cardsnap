import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import Vision

/// Microsoft Lens-style flex crop view.
/// Shows the image with 4 draggable corner handles forming a trapezoid.
/// On "Confirm", applies a perspective correction transform using CIFilter.
struct FlexCropView: View {
    @State private var image: UIImage
    var onCrop: (UIImage) -> Void
    var onCancel: () -> Void

    init(image: UIImage, onCrop: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
        self._image = State(initialValue: image.normalized())
        self.onCrop = onCrop
        self.onCancel = onCancel
    }

    // Corner positions as unit fractions (0..1) of the displayed image frame
    @State private var tl: CGPoint = CGPoint(x: 0.08, y: 0.08)
    @State private var tr: CGPoint = CGPoint(x: 0.92, y: 0.08)
    @State private var bl: CGPoint = CGPoint(x: 0.08, y: 0.92)
    @State private var br: CGPoint = CGPoint(x: 0.92, y: 0.92)

    @State private var imageFrame: CGRect = .zero
    private let haptic = UISelectionFeedbackGenerator()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top toolbar
                 HStack {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(12)
                            .glassEffect(in: Circle())
                    }
                    Spacer()
                    Text("Flex Crop")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        applyPerspectiveCorrection()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.green)
                            .padding(12)
                            .glassEffect(in: Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 16)

                Spacer()

                // Image + overlay
                GeometryReader { geo in
                    let frame = calculateImageFrame(containerSize: geo.size, imageSize: image.size)
                    ZStack {
                        // Source image
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: frame.width, height: frame.height)
                            .position(x: frame.midX, y: frame.midY)
                            .onAppear {
                                detectBusinessCard()
                            }

                        // Trapezoid overlay
                        TrapezoidOverlay(
                            tl: absolute(tl, in: frame),
                            tr: absolute(tr, in: frame),
                            bl: absolute(bl, in: frame),
                            br: absolute(br, in: frame)
                        )

                        // Corner handles
                        cornerHandle(fraction: $tl, imageFrame: frame, color: .cyan)
                        cornerHandle(fraction: $tr, imageFrame: frame, color: .cyan)
                        cornerHandle(fraction: $bl, imageFrame: frame, color: .cyan)
                        cornerHandle(fraction: $br, imageFrame: frame, color: .cyan)
                    }
                }

                Spacer()

                // Hint
                Text("Drag the corners to fit around the card edges")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Corner handle
    private func cornerHandle(fraction: Binding<CGPoint>, imageFrame: CGRect, color: Color) -> some View {
        let abs = absolute(fraction.wrappedValue, in: imageFrame)
        return Circle()
            .fill(color)
            .frame(width: 28, height: 28)
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .shadow(color: .black.opacity(0.4), radius: 4)
            .position(abs)
            .gesture(
                DragGesture()
                    .onChanged { val in
                        haptic.selectionChanged()
                        let newFrac = CGPoint(
                            x: ((val.location.x - imageFrame.minX) / imageFrame.width).clamped(to: 0.0...1.0),
                            y: ((val.location.y - imageFrame.minY) / imageFrame.height).clamped(to: 0.0...1.0)
                        )
                        fraction.wrappedValue = newFrac
                    }
            )
    }

    private func absolute(_ frac: CGPoint, in frame: CGRect) -> CGPoint {
        CGPoint(
            x: frame.minX + frac.x * frame.width,
            y: frame.minY + frac.y * frame.height
        )
    }

    private func calculateImageFrame(containerSize: CGSize, imageSize: CGSize) -> CGRect {
        guard imageSize.width > 0 && imageSize.height > 0 else { return .zero }
        let containerAspect = containerSize.width / containerSize.height
        let imageAspect = imageSize.width / imageSize.height
        
        var w: CGFloat = 0
        var h: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        
        if imageAspect > containerAspect {
            // Image is wider than container aspect ratio (letterboxed top/bottom)
            w = containerSize.width
            h = containerSize.width / imageAspect
            x = 0
            y = (containerSize.height - h) / 2
        } else {
            // Image is taller than container aspect ratio (pillarboxed sides)
            h = containerSize.height
            w = containerSize.height * imageAspect
            x = (containerSize.width - w) / 2
            y = 0
        }
        
        return CGRect(x: x, y: y, width: w, height: h)
    }

    // MARK: - Perspective Correction
    private func applyPerspectiveCorrection() {
        guard let cgImage = image.cgImage else { onCrop(image); return }

        let iw = CGFloat(cgImage.width)
        let ih = CGFloat(cgImage.height)

        // Map unit fractions back to actual pixel coordinates
        let tlPx = CGPoint(x: tl.x * iw,         y: tl.y * ih)
        let trPx = CGPoint(x: tr.x * iw,         y: tr.y * ih)
        let blPx = CGPoint(x: bl.x * iw,         y: bl.y * ih)
        let brPx = CGPoint(x: br.x * iw,         y: br.y * ih)

        // CoreImage uses bottom-left origin, so flip Y
        let tlCI = CGPoint(x: tlPx.x, y: ih - tlPx.y)
        let trCI = CGPoint(x: trPx.x, y: ih - trPx.y)
        let blCI = CGPoint(x: blPx.x, y: ih - blPx.y)
        let brCI = CGPoint(x: brPx.x, y: ih - brPx.y)

        let filter = CIFilter.perspectiveCorrection()
        filter.inputImage = CIImage(cgImage: cgImage)
        filter.topLeft     = tlCI
        filter.topRight    = trCI
        filter.bottomLeft  = blCI
        filter.bottomRight = brCI

        let context = CIContext()
        if let output = filter.outputImage,
           let resultCG = context.createCGImage(output, from: output.extent) {
            onCrop(UIImage(cgImage: resultCG))
        } else {
            onCrop(image) // fallback to original
        }
    }

    // MARK: - Auto-Detect Rectangle
    private func detectBusinessCard() {
        guard let cgImage = image.cgImage else { return }
        let request = VNDetectDocumentSegmentationRequest { req, err in
            guard let result = req.results?.first as? VNRectangleObservation else { return }
            DispatchQueue.main.async {
                // Vision uses bottom-left origin (0..1)
                // We need top-left origin (0..1) for our UI
                self.tl = CGPoint(x: result.topLeft.x, y: 1.0 - result.topLeft.y)
                self.tr = CGPoint(x: result.topRight.x, y: 1.0 - result.topRight.y)
                self.bl = CGPoint(x: result.bottomLeft.x, y: 1.0 - result.bottomLeft.y)
                self.br = CGPoint(x: result.bottomRight.x, y: 1.0 - result.bottomRight.y)
            }
        }
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
}

// MARK: - Trapezoid overlay shape
struct TrapezoidOverlay: View {
    let tl, tr, bl, br: CGPoint

    var body: some View {
        ZStack {
            // Dimming mask outside the trapezoid
            TrapezoidMask(tl: tl, tr: tr, bl: bl, br: br)
                .fill(Color.black.opacity(0.45))

            // Outline
            TrapezoidBorder(tl: tl, tr: tr, bl: bl, br: br)
                .stroke(Color.cyan, lineWidth: 2)

            // Edge midpoint markers
            edgeDot(between: tl, and: tr)
            edgeDot(between: tr, and: br)
            edgeDot(between: br, and: bl)
            edgeDot(between: bl, and: tl)
        }
    }

    private func edgeDot(between a: CGPoint, and b: CGPoint) -> some View {
        let mid = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
        return Circle()
            .fill(Color.white.opacity(0.6))
            .frame(width: 8, height: 8)
            .position(mid)
    }
}

struct TrapezoidBorder: Shape {
    let tl, tr, bl, br: CGPoint
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: tl); p.addLine(to: tr)
        p.addLine(to: br); p.addLine(to: bl)
        p.closeSubpath()
        return p
    }
}

struct TrapezoidMask: Shape {
    let tl, tr, bl, br: CGPoint
    func path(in rect: CGRect) -> Path {
        // Full rect minus the trapezoid (even-odd fill for the "hole")
        var p = Path()
        p.addRect(rect)
        p.move(to: tl); p.addLine(to: tr)
        p.addLine(to: br); p.addLine(to: bl)
        p.closeSubpath()
        return p
    }
    // Use even-odd to punch out the center
    var fillStyle: FillStyle { FillStyle(eoFill: true) }
}

// MARK: - Helpers
extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

extension UIImage {
    /// Normalizes image orientation to .up so CoreImage and Vision don't get confused
    func normalized() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage ?? self
    }
}
