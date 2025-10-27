import UIKit
import SwiftUI
import AVFoundation

/// Service for camera and photo library access
/// Wraps UIImagePickerController for SwiftUI usage
class CameraService: NSObject {

    static let shared = CameraService()

    private var pickerController: UIImagePickerController?
    private var completionHandler: ((UIImage?) -> Void)?

    private override init() {
        super.init()
    }

    // MARK: - Public Methods

    /// Check if camera is available on this device
    var isCameraAvailable: Bool {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    /// Check if photo library is available
    var isPhotoLibraryAvailable: Bool {
        return UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
    }

    /// Check camera authorization status
    var cameraAuthorizationStatus: AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: .video)
    }

    /// Request camera permission
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    /// Present camera to capture photo
    func presentCamera(from viewController: UIViewController, completion: @escaping (UIImage?) -> Void) {
        guard isCameraAvailable else {
            print("❌ Camera not available on this device")
            completion(nil)
            return
        }

        guard cameraAuthorizationStatus != .denied && cameraAuthorizationStatus != .restricted else {
            print("❌ Camera permission denied or restricted")
            completion(nil)
            return
        }

        // Request permission if not determined
        if cameraAuthorizationStatus == .notDetermined {
            requestCameraPermission { [weak self] granted in
                guard granted else {
                    completion(nil)
                    return
                }
                self?.showImagePicker(sourceType: .camera, from: viewController, completion: completion)
            }
        } else {
            showImagePicker(sourceType: .camera, from: viewController, completion: completion)
        }
    }

    /// Present photo library to select photo
    func presentPhotoLibrary(from viewController: UIViewController, completion: @escaping (UIImage?) -> Void) {
        guard isPhotoLibraryAvailable else {
            print("❌ Photo library not available")
            completion(nil)
            return
        }

        showImagePicker(sourceType: .photoLibrary, from: viewController, completion: completion)
    }

    /// Present action sheet to choose between camera and photo library
    func presentPhotoOptions(from viewController: UIViewController, completion: @escaping (UIImage?) -> Void) {
        let alert = UIAlertController(
            title: "Add Photo",
            message: "Choose a photo source",
            preferredStyle: .actionSheet
        )

        // Camera option
        if isCameraAvailable {
            alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { [weak self] _ in
                self?.presentCamera(from: viewController, completion: completion)
            })
        }

        // Photo library option
        if isPhotoLibraryAvailable {
            alert.addAction(UIAlertAction(title: "Choose from Library", style: .default) { [weak self] _ in
                self?.presentPhotoLibrary(from: viewController, completion: completion)
            })
        }

        // Cancel
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(nil)
        })

        // For iPad - configure popover
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = viewController.view
            popoverController.sourceRect = CGRect(
                x: viewController.view.bounds.midX,
                y: viewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popoverController.permittedArrowDirections = []
        }

        viewController.present(alert, animated: true)
    }

    // MARK: - Private Methods

    private func showImagePicker(
        sourceType: UIImagePickerController.SourceType,
        from viewController: UIViewController,
        completion: @escaping (UIImage?) -> Void
    ) {
        self.completionHandler = completion

        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        picker.allowsEditing = true // Enable cropping/editing

        self.pickerController = picker

        viewController.present(picker, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension CameraService: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        picker.dismiss(animated: true)

        // Get edited image if available, otherwise use original
        var selectedImage: UIImage?
        if let editedImage = info[.editedImage] as? UIImage {
            selectedImage = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            selectedImage = originalImage
        }

        completionHandler?(selectedImage)
        completionHandler = nil
        pickerController = nil
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)

        completionHandler?(nil)
        completionHandler = nil
        pickerController = nil
    }
}

// MARK: - SwiftUI Helpers

/// SwiftUI wrapper for presenting camera/photo picker
struct ImagePicker: UIViewControllerRepresentable {

    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedImage: UIImage?

    let sourceType: UIImagePickerController.SourceType

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }

            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
