import Foundation

struct Podcast
{
    let name: String
    let artistName: String
    
    static let mockPodcasts = [
        Podcast(name: "Let's Build that App", artistName: "Brian Voong"),
        Podcast(name: "Fragmented Podcasts", artistName: "Kaushik and Don"),
        Podcast(name: "Swift by Sundell", artistName: "John Sundell"),
        Podcast(name: "Swift Unwrapped", artistName: "JP & Jesse"),
        Podcast(name: "Android Developers Backstage", artistName: "Android Developers")
    ]
}
