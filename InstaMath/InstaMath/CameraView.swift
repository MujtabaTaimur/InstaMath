import SwiftUI
import AVFoundation

#if canImport(UIKit)
import UIKit
#endif

#if os(iOS)
struct CameraView: View {
    @Binding var image: UIImage?
    @Binding var isShown: Bool
    @StateObject private var camera = CameraModel()
    
    var body: some View {
        ZStack {
            CameraPreviewView(camera: camera)
            
            if camera.isTaken {
                VStack {
                    HStack {
                        Button(action: camera.retakePicture) {
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.75))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if let image = camera.capturedImage {
                                self.image = image
                                isShown = false
                            }
                        }) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.75))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                }
            } else {
                VStack {
                    Spacer()
                    
                    Button(action: camera.takePicture) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 65, height: 65)
                            
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: 75, height: 75)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            camera.checkPermissions()
        }
        .alert("Camera Access Required", isPresented: $camera.showPermissionAlert) {
            Button("Settings", role: .none) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {
                isShown = false
            }
        } message: {
            Text("Please allow camera access in Settings to use this feature.")
        }
    }
}

class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var isTaken = false
    @Published var capturedImage: UIImage?
    @Published var session = AVCaptureSession()
    @Published var showPermissionAlert = false
    @Published var error: Error?
    
    private let output = AVCapturePhotoOutput()
    private var permissionGranted = false
    
    override init() {
        super.init()
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            setup()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionGranted = granted
                    if granted {
                        self?.setup()
                    } else {
                        self?.showPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert = true
        @unknown default:
            break
        }
    }
    
    private func setup() {
        do {
            session.beginConfiguration()
            
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                     for: .video,
                                                     position: .back) else {
                print("Failed to get camera device")
                return
            }
            
            let input = try AVCaptureDeviceInput(device: device)
            
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            
            session.commitConfiguration()
            
            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.session.startRunning()
            }
        } catch {
            print("Error setting up camera: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    func takePicture() {
        DispatchQueue.global(qos: .background).async {
            let settings = AVCapturePhotoSettings()
            self.output.capturePhoto(with: settings, delegate: self)
        }
    }
    
    func retakePicture() {
        DispatchQueue.main.async { [weak self] in
            self?.isTaken = false
            self?.capturedImage = nil
            
            DispatchQueue.global(qos: .background).async {
                self?.session.startRunning()
            }
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                    didFinishProcessingPhoto photo: AVCapturePhoto,
                    error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            self.error = error
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("Error converting photo data to image")
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.capturedImage = image
            self?.isTaken = true
            self?.session.stopRunning()
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var camera: CameraModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: camera.session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                 didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#else
struct CameraView: View {
    @Binding var image: Image?
    @Binding var isShown: Bool
    
    var body: some View {
        Text("Camera not available on this platform")
            .padding()
    }
}
#endif 