import SwiftUI
import UIKit

struct ImageCropperView: View {
    let image: UIImage
    let onCancel: () -> Void
    let onCrop: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var currentCropSize: CGFloat = 0

    private let minimumScale: CGFloat = 1

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.opacity(0.95)
                    .ignoresSafeArea()

                GeometryReader { geometry in
                    let cropSize = min(geometry.size.width, geometry.size.height - 160)
                    VStack(spacing: 32) {
                        Spacer()

                        ZStack {
                            croppedImageView(cropSize: cropSize)
                                .frame(width: cropSize, height: cropSize)
                                .clipped()
                                .contentShape(Rectangle())
                                .gesture(dragGesture(cropSize: cropSize))
                                .gesture(magnificationGesture(cropSize: cropSize))

                            cropOverlay(size: cropSize)
                        }
                        .frame(maxWidth: .infinity)
                        .onAppear {
                            currentCropSize = cropSize
                        }
                        .onChange(of: cropSize) { _, newSize in
                            currentCropSize = newSize
                            offset = clampedOffset(for: offset, cropSize: newSize)
                        }

                        Text("Pinch and drag to position your photo")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.8))

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .principal) {
                    Text("Adjust Photo")
                        .font(.headline)
                        .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Choose") {
                        performCrop()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            resetState()
        }
    }

    private func croppedImageView(cropSize: CGFloat) -> some View {
        let displaySize = scaledDisplaySize(for: cropSize)

        return Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: displaySize.width, height: displaySize.height)
            .offset(offset)
    }

    private func cropOverlay(size: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .strokeBorder(Color.white.opacity(0.85), lineWidth: 1.5)
            .frame(width: size, height: size)
            .allowsHitTesting(false)
    }

    private func dragGesture(cropSize: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let translation = value.translation
                let newOffset = CGSize(width: lastOffset.width + translation.width, height: lastOffset.height + translation.height)
                offset = clampedOffset(for: newOffset, cropSize: cropSize)
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private func magnificationGesture(cropSize: CGFloat) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newScale = max(minimumScale, lastScale * value)
                scale = newScale
                offset = clampedOffset(for: offset, cropSize: cropSize)
            }
            .onEnded { _ in
                lastScale = scale
                offset = clampedOffset(for: offset, cropSize: cropSize)
                lastOffset = offset
            }
    }

    private func clampedOffset(for proposedOffset: CGSize, cropSize: CGFloat) -> CGSize {
        let displaySize = scaledDisplaySize(for: cropSize)
        let maxOffsetX = max((displaySize.width - cropSize) / 2, 0)
        let maxOffsetY = max((displaySize.height - cropSize) / 2, 0)
        let clampedX = min(max(proposedOffset.width, -maxOffsetX), maxOffsetX)
        let clampedY = min(max(proposedOffset.height, -maxOffsetY), maxOffsetY)
        return CGSize(width: clampedX, height: clampedY)
    }

    private func performCrop() {
        let cropSize = currentCropSize == 0 ? 512 : currentCropSize

        let rendererContent = croppedImageView(cropSize: cropSize)
            .frame(width: cropSize, height: cropSize)
            .clipped()

        let renderer = ImageRenderer(content: rendererContent)
        renderer.scale = UIScreen.main.scale

        if let renderedImage = renderer.uiImage {
            onCrop(renderedImage)
        }

        dismiss()
    }

    private func resetState() {
        scale = 1
        lastScale = 1
        offset = .zero
        lastOffset = .zero
    }
    private func scaledDisplaySize(for cropSize: CGFloat) -> CGSize {
        let aspectRatio = max(image.size.width / max(image.size.height, 0.0001), 0.0001)

        let baseWidth: CGFloat
        let baseHeight: CGFloat

        if aspectRatio > 1 {
            baseHeight = cropSize
            baseWidth = cropSize * aspectRatio
        } else {
            baseWidth = cropSize
            baseHeight = cropSize / aspectRatio
        }

        return CGSize(width: baseWidth * scale, height: baseHeight * scale)
    }
}
