import SwiftUI

/// Reusable photo grid view for displaying and managing attachments
struct PhotoGridView: View {

    let attachments: [Attachment]
    let onAddPhoto: () -> Void
    let onDeletePhoto: (Attachment) -> Void
    let onSelectPhoto: (Attachment) -> Void

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Photos")
                    .font(.headline)

                Spacer()

                Button(action: onAddPhoto) {
                    HStack(spacing: 4) {
                        Image(systemName: "camera.fill")
                        Text("Add")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }

            if attachments.isEmpty {
                emptyStateView
            } else {
                photoGrid
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text("No photos yet")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button(action: onAddPhoto) {
                Text("Add First Photo")
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var photoGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(attachments) { attachment in
                PhotoThumbnailView(
                    attachment: attachment,
                    onTap: { onSelectPhoto(attachment) },
                    onDelete: { onDeletePhoto(attachment) }
                )
            }
        }
    }
}

// MARK: - Photo Thumbnail View

struct PhotoThumbnailView: View {
    let attachment: Attachment
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var showDeleteConfirmation = false

    private let fileStorage = FileStorageService.shared

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Thumbnail
            Button(action: onTap) {
                Group {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: 100, height: 100)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(PlainButtonStyle())

            // Delete button
            Button(action: { showDeleteConfirmation = true }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .background(Circle().fill(Color.white))
            }
            .offset(x: 8, y: -8)
        }
        .task {
            await loadThumbnail()
        }
        .confirmationDialog(
            "Delete Photo",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this photo? This action cannot be undone.")
        }
    }

    private func loadThumbnail() async {
        isLoading = true

        do {
            let loadedImage = try await Task {
                try fileStorage.getImage(relativePath: attachment.relativePath)
            }.value

            // Create thumbnail
            image = await createThumbnail(from: loadedImage, size: CGSize(width: 300, height: 300))
        } catch {
            print("Failed to load thumbnail: \(error)")
        }

        isLoading = false
    }

    private func createThumbnail(from image: UIImage, size: CGSize) async -> UIImage {
        return await Task {
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: size))
            }
        }.value
    }
}

// MARK: - Full-Size Photo View

struct PhotoDetailView: View {
    let attachment: Attachment

    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    private let fileStorage = FileStorageService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .gesture(magnificationGesture)
                } else if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                        Text("Failed to load image")
                            .foregroundColor(.white)
                    }
                }
            }
            .navigationTitle("Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .toolbarBackground(Color.black.opacity(0.8), for: .navigationBar)
            .task {
                await loadImage()
            }
        }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = lastScale * value
            }
            .onEnded { value in
                lastScale = scale
                // Limit scale range
                if scale < 1.0 {
                    withAnimation {
                        scale = 1.0
                        lastScale = 1.0
                    }
                } else if scale > 5.0 {
                    withAnimation {
                        scale = 5.0
                        lastScale = 5.0
                    }
                }
            }
    }

    private func loadImage() async {
        isLoading = true

        do {
            image = try await Task {
                try fileStorage.getImage(relativePath: attachment.relativePath)
            }.value
        } catch {
            print("Failed to load image: \(error)")
        }

        isLoading = false
    }
}

// MARK: - Photo Picker Button

struct PhotoPickerButton: View {
    @State private var showingSourcePicker = false
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @Binding var selectedImage: UIImage?

    var body: some View {
        Button(action: { showingSourcePicker = true }) {
            HStack {
                Image(systemName: "camera.fill")
                Text("Add Photo")
            }
        }
        .confirmationDialog("Choose Photo Source", isPresented: $showingSourcePicker) {
            Button("Take Photo") {
                showingCamera = true
            }
            Button("Choose from Library") {
                showingPhotoLibrary = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
        }
        .sheet(isPresented: $showingPhotoLibrary) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
        }
    }
}
