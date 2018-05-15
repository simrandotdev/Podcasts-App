import Foundation

struct Podcast
{
    let name: String
    let artistName: String
    
    static let mockPodcasts = [
        Podcast(name: "Let's Build that App", artistName: "Brian Voong"),
        Podcast(name: "Fragmented Podcasts", artistName: "Kaushik and Don")
    ]
}
