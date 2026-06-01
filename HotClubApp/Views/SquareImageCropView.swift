import PhotosUI
import SwiftUI

struct SquareImageCropView: View {
    let displayImage: UIImage
    let exportImage: UIImage
    var onSave: (Data) -> Void
    var onCancel: () -> Void

    private let imageSize: CGSize

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var cropSide: CGFloat = 0
    @State private var saveError: String?
    @State private var isSaving = false

    init(
        displayImage: UIImage,
        exportImage: UIImage,
        onSave: @escaping (Data) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.displayImage = displayImage
        self.exportImage = exportImage
        self.onSave = onSave
        self.onCancel = onCancel
        imageSize = displayImage.size
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let side = min(geo.size.width, geo.size.height) - 48
                ZStack {
                    Color.black.ignoresSafeArea()

                    cropCanvas(side: side)
                        .frame(width: side, height: side)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)

                    squareOverlay(side: side)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .allowsHitTesting(false)

                    VStack {
                        Spacer()
                        Text("Pinch to zoom, drag to reposition")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(.bottom, 24)
                    }
                }
                .onAppear {
                    cropSide = side
                    offset = .zero
                    lastOffset = .zero
                }
                .onChange(of: side) { _, newSide in
                    cropSide = newSide
                    offset = ImageProcessor.clampCropOffset(
                        offset,
                        scale: scale,
                        imageSize: imageSize,
                        cropSide: newSide
                    )
                    lastOffset = offset
                }
            }
            .navigationTitle("Align photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.85), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", action: onCancel)
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("OK") {
                            saveCrop()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .alert("Could not save photo", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveError ?? "")
            }
        }
    }

    @ViewBuilder
    private func cropCanvas(side: CGFloat) -> some View {
        Image(uiImage: displayImage)
            .resizable()
            .scaledToFill()
            .scaleEffect(scale)
            .offset(offset)
            .frame(width: side, height: side)
            .clipped()
            .contentShape(Rectangle())
            .gesture(dragGesture(side: side))
            .simultaneousGesture(magnificationGesture(side: side))
    }

    @ViewBuilder
    private func squareOverlay(side: CGFloat) -> some View {
        GeometryReader { geo in
            let originX = (geo.size.width - side) / 2
            let originY = (geo.size.height - side) / 2
            let hole = CGRect(x: originX, y: originY, width: side, height: side)

            ZStack {
                Color.black.opacity(0.55)
                    .mask {
                        Rectangle()
                            .overlay {
                                Rectangle()
                                    .frame(width: side, height: side)
                                    .position(x: hole.midX, y: hole.midY)
                                    .blendMode(.destinationOut)
                            }
                    }

                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color.white.opacity(0.9), lineWidth: 2)
                    .frame(width: side, height: side)
                    .position(x: hole.midX, y: hole.midY)
            }
        }
    }

    private func dragGesture(side: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let proposed = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
                offset = ImageProcessor.clampCropOffset(
                    proposed,
                    scale: scale,
                    imageSize: imageSize,
                    cropSide: side
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private func magnificationGesture(side: CGFloat) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let proposed = min(max(lastScale * value, 1), 4)
                scale = proposed
                offset = ImageProcessor.clampCropOffset(
                    offset,
                    scale: proposed,
                    imageSize: imageSize,
                    cropSide: side
                )
            }
            .onEnded { _ in
                lastScale = scale
                lastOffset = offset
            }
    }

    private func saveCrop() {
        guard cropSide > 0, !isSaving else { return }

        isSaving = true
        let outputSide = ImageProcessor.cropOutputEdge
        let offsetRatio = CGSize(
            width: offset.width / cropSide,
            height: offset.height / cropSide
        )
        let exportOffset = CGSize(
            width: offsetRatio.width * outputSide,
            height: offsetRatio.height * outputSide
        )
        let cropScale = scale
        let imageForExport = exportImage

        Task {
            do {
                let jpeg = try await Task.detached(priority: .userInitiated) {
                    try ImageProcessor.encodeSquareCrop(
                        image: imageForExport,
                        scale: cropScale,
                        offset: exportOffset,
                        outputSide: outputSide
                    )
                }.value

                onSave(jpeg)
                isSaving = false
            } catch {
                saveError = error.localizedDescription
                isSaving = false
            }
        }
    }
}

private struct PendingCropImage: Identifiable {
    let id = UUID()
    let displayImage: UIImage
    let exportImage: UIImage
}

struct SideImageField: View {
    @Binding var croppedPhotoJPEG: Data?
    var label: String = "Side image"

    @State private var pickerItem: PhotosPickerItem?
    @State private var pendingCrop: PendingCropImage?
    @State private var previewImage: UIImage?
    @State private var loadError: String?
    @State private var isPreparingPhoto = false
    @State private var showPhotoLibrary = false
    @State private var showCamera = false

    private var photoActionTitle: String {
        croppedPhotoJPEG == nil ? label : "Change photo"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.secondary.opacity(0.35), lineWidth: 1)
                    }
                    .accessibilityLabel("Cropped side image preview")
            }

            Menu {
                if CameraImagePicker.isAvailable {
                    Button {
                        showCamera = true
                    } label: {
                        Label("Take Photo", systemImage: "camera")
                    }
                }
                Button {
                    showPhotoLibrary = true
                } label: {
                    Label("Choose from Library", systemImage: "photo.on.rectangle")
                }
            } label: {
                Label(photoActionTitle, systemImage: "photo")
            }
            .disabled(isPreparingPhoto)

            if isPreparingPhoto {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Preparing photo…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if croppedPhotoJPEG != nil {
                Button("Remove photo", role: .destructive) {
                    croppedPhotoJPEG = nil
                    previewImage = nil
                    pickerItem = nil
                }
            }

            Text("Use the camera or photo library. Drag and pinch to align before tapping OK.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .photosPicker(
            isPresented: $showPhotoLibrary,
            selection: $pickerItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: croppedPhotoJPEG) { _, newValue in
            Task { await refreshPreview(from: newValue) }
        }
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task { await loadPickerItem(newItem) }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraImagePicker(
                onImagePicked: { image in
                    Task { await prepareAndPresentCrop(image: image) }
                },
                onCancel: {}
            )
            .ignoresSafeArea()
        }
        .fullScreenCover(item: $pendingCrop) { pending in
            SquareImageCropView(
                displayImage: pending.displayImage,
                exportImage: pending.exportImage,
                onSave: { jpeg in
                    croppedPhotoJPEG = jpeg
                    pendingCrop = nil
                    pickerItem = nil
                },
                onCancel: {
                    pendingCrop = nil
                    pickerItem = nil
                }
            )
        }
        .alert("Could not load photo", isPresented: Binding(
            get: { loadError != nil },
            set: { if !$0 { loadError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(loadError ?? "")
        }
    }

    private func refreshPreview(from data: Data?) async {
        guard let data else {
            previewImage = nil
            return
        }

        let image = await Task.detached(priority: .utility) {
            UIImage(data: data)
        }.value
        previewImage = image
    }

    private func loadPickerItem(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                loadError = "The selected photo could not be read."
                pickerItem = nil
                return
            }
            try await prepareAndPresentCrop(data: data)
        } catch {
            loadError = error.localizedDescription
            pickerItem = nil
        }
    }

    private func prepareAndPresentCrop(data: Data) async throws {
        isPreparingPhoto = true
        defer { isPreparingPhoto = false }

        let prepared = try await Task.detached(priority: .userInitiated) {
            try ImageProcessor.prepareForCrop(data)
        }.value

        pendingCrop = PendingCropImage(
            displayImage: prepared.display,
            exportImage: prepared.export
        )
    }

    private func prepareAndPresentCrop(image: UIImage) async {
        isPreparingPhoto = true
        defer { isPreparingPhoto = false }

        do {
            let prepared = try await Task.detached(priority: .userInitiated) {
                try ImageProcessor.prepareForCrop(image)
            }.value

            pendingCrop = PendingCropImage(
                displayImage: prepared.display,
                exportImage: prepared.export
            )
        } catch {
            loadError = error.localizedDescription
        }
    }
}
