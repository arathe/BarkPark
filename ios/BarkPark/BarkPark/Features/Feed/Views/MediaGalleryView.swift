import SwiftUI
import AVKit

struct MediaGalleryView: View {
    let media: [PostMedia]
    @State private var selectedIndex = 0
    
    var body: some View {
        if media.count == 1 {
            singleMediaView(media[0])
        } else if media.count == 2 {
            twoMediaGrid
        } else if media.count == 3 {
            threeMediaGrid
        } else if media.count >= 4 {
            fourMediaGrid
        }
    }
    
    private func singleMediaView(_ item: PostMedia) -> some View {
        MediaItemView(media: item)
            .aspectRatio(contentMode: .fit)
            .frame(maxHeight: 400)
    }
    
    private var twoMediaGrid: some View {
        HStack(spacing: 2) {
            ForEach(media.prefix(2)) { item in
                MediaItemView(media: item)
                    .aspectRatio(1, contentMode: .fill)
                    .clipped()
            }
        }
        .frame(height: 250)
    }
    
    private var threeMediaGrid: some View {
        HStack(spacing: 2) {
            MediaItemView(media: media[0])
                .aspectRatio(1, contentMode: .fill)
                .clipped()
            
            VStack(spacing: 2) {
                ForEach(media[1...2]) { item in
                    MediaItemView(media: item)
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                }
            }
        }
        .frame(height: 250)
    }
    
    private var fourMediaGrid: some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                ForEach(media.prefix(2)) { item in
                    MediaItemView(media: item)
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                }
            }
            
            HStack(spacing: 2) {
                ForEach(media[2..<min(4, media.count)]) { item in
                    ZStack {
                        MediaItemView(media: item)
                            .aspectRatio(1, contentMode: .fill)
                            .clipped()
                        
                        if media.count > 4 && item.id == media[3].id {
                            Rectangle()
                                .fill(Color.black.opacity(0.6))
                            
                            Text("+\(media.count - 4)")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .frame(height: 250)
    }
}

struct MediaItemView: View {
    let media: PostMedia
    @State private var showFullScreen = false
    
    var body: some View {
        Button(action: { showFullScreen = true }) {
            if media.mediaType == .video {
                VideoThumbnailView(media: media)
            } else {
                AsyncImage(url: URL(string: media.mediaUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            ProgressView()
                                .tint(BarkParkDesign.Colors.dogPrimary)
                        )
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showFullScreen) {
            MediaFullScreenView(media: media)
        }
    }
}

struct VideoThumbnailView: View {
    let media: PostMedia
    
    var body: some View {
        ZStack {
            if let thumbnailUrl = media.thumbnailUrl {
                AsyncImage(url: URL(string: thumbnailUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }
            
            // Play button overlay
            Circle()
                .fill(Color.black.opacity(0.6))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "play.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .offset(x: 2) // Slight offset for visual balance
                )
            
            // Duration label
            if let duration = media.duration {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(formatDuration(duration))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.6))
                            )
                            .padding(8)
                    }
                }
            }
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

struct MediaFullScreenView: View {
    let media: PostMedia
    @Environment(\.dismiss) var dismiss
    @State private var isPlaying = true
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if media.mediaType == .video {
                VideoPlayer(player: AVPlayer(url: URL(string: media.mediaUrl)!))
                    .ignoresSafeArea()
            } else {
                AsyncImage(url: URL(string: media.mediaUrl)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    ProgressView()
                        .tint(.white)
                }
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                            )
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Single image
        MediaGalleryView(media: [
            PostMedia(
                id: 1,
                mediaType: .photo,
                mediaUrl: "https://picsum.photos/400/300",
                thumbnailUrl: nil,
                width: 400,
                height: 300,
                duration: nil,
                orderIndex: 0
            )
        ])
        
        // Multiple images
        MediaGalleryView(media: [
            PostMedia(id: 1, mediaType: .photo, mediaUrl: "https://picsum.photos/400/300", thumbnailUrl: nil, width: 400, height: 300, duration: nil, orderIndex: 0),
            PostMedia(id: 2, mediaType: .photo, mediaUrl: "https://picsum.photos/401/301", thumbnailUrl: nil, width: 400, height: 300, duration: nil, orderIndex: 1),
            PostMedia(id: 3, mediaType: .photo, mediaUrl: "https://picsum.photos/402/302", thumbnailUrl: nil, width: 400, height: 300, duration: nil, orderIndex: 2),
            PostMedia(id: 4, mediaType: .photo, mediaUrl: "https://picsum.photos/403/303", thumbnailUrl: nil, width: 400, height: 300, duration: nil, orderIndex: 3)
        ])
    }
    .padding()
}