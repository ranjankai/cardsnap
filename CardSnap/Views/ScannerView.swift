#if !targetEnvironment(macCatalyst)
import VisionKit
#endif
import SwiftUI

/// Wraps VNDocumentCameraViewController for SwiftUI on iOS.
/// On Mac Catalyst, shows a placeholder — use the photo picker instead.
struct ScannerView: UIViewControllerRepresentable {
    var onScan: (UIImage) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        #if targetEnvironment(macCatalyst)
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground

        // Close button top-right
        let closeBtn = UIButton(type: .system)
        closeBtn.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeBtn.tintColor = .secondaryLabel
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        closeBtn.addAction(UIAction { _ in vc.dismiss(animated: true) }, for: .touchUpInside)
        vc.view.addSubview(closeBtn)

        let imageView = UIImageView(image: UIImage(systemName: "camera.slash"))
        imageView.tintColor = .tertiaryLabel
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(imageView)

        let label = UILabel()
        label.text = "Camera not available on Mac.\nUse \"Import from Photos\" instead."
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(label)

        NSLayoutConstraint.activate([
            closeBtn.topAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeBtn.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -20),
            closeBtn.widthAnchor.constraint(equalToConstant: 32),
            closeBtn.heightAnchor.constraint(equalToConstant: 32),

            imageView.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor, constant: -40),
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60),

            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            label.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            label.widthAnchor.constraint(equalTo: vc.view.widthAnchor, multiplier: 0.75)
        ])
        return vc
        #else
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
        #endif
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    #if targetEnvironment(macCatalyst)
    class Coordinator: NSObject {
        var onScan: (UIImage) -> Void
        init(onScan: @escaping (UIImage) -> Void) { self.onScan = onScan }
    }
    #else
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var onScan: (UIImage) -> Void
        init(onScan: @escaping (UIImage) -> Void) { self.onScan = onScan }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFinishWith scan: VNDocumentCameraScan) {
            let image = scan.imageOfPage(at: 0)
            controller.dismiss(animated: true) {
                self.onScan(image)
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFailWithError error: Error) {
            print("[ScannerView] Camera error: \(error.localizedDescription)")
            controller.dismiss(animated: true)
        }
    }
    #endif
}
