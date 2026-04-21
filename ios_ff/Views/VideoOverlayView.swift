import SwiftUI

struct VideoOverlayView: View {
    let video: VideoModel
    @State private var isLiked = false

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                Spacer()
                Text(video.author)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                Text(video.description)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Image(systemName: "music.note")
                        .font(.system(size: 12))
                    Text(video.musicName)
                        .font(.system(size: 13))
                        .lineLimit(1)
                }
                .foregroundColor(.white)
            }
            .padding(.leading, 16)
            .padding(.bottom, 16)

            Spacer()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: video.authorAvatar)
                    .font(.system(size: 44))
                    .foregroundColor(.white)

                ActionButton(icon: isLiked ? "heart.fill" : "heart",
                           count: formatCount(video.likes),
                           color: isLiked ? .red : .white) { isLiked.toggle() }

                ActionButton(icon: "ellipsis.bubble",
                           count: formatCount(video.comments),
                           color: .white) {}

                ActionButton(icon: "arrowshape.turn.up.right",
                           count: formatCount(video.shares),
                           color: .white) {}

                ActionButton(icon: "bookmark", count: "", color: .white) {}
            }
            .padding(.trailing, 12)
            .padding(.bottom, 16)
        }
    }

    private func formatCount(_ n: Int) -> String {
        if n >= 10000 { return String(format: "%.1fw", Double(n) / 10000.0) }
        if n >= 1000 { return String(format: "%.1fk", Double(n) / 1000.0) }
        return "\(n)"
    }
}

struct ActionButton: View {
    let icon: String
    let count: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)
                if !count.isEmpty {
                    Text(count)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
    }
}
