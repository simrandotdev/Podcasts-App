import SwiftUI

struct PodcastArtwork: View {
    let urlString: String?

    var body: some View {
        AsyncImage(url: URL(string: urlString ?? "")) { phase in
            if let image = phase.image {
                image.resizable().scaledToFit()
            } else {
                ZStack {
                    Color.secondary.opacity(0.12)
                    Image(systemName: "mic.fill")
                        .resizable()
                        .scaledToFit()
                        .padding(20)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityHidden(true)
    }
}
