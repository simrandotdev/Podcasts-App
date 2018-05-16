import Foundation

struct Podcast : Codable
{
    var trackName: String?
    var artistName: String?
    
    static let mockPodcasts = [
        Podcast(trackName: "Let's Build that App", artistName: "Brian Voong"),
        Podcast(trackName: "Fragmented Podcasts", artistName: "Kaushik and Don"),
        Podcast(trackName: "Swift by Sundell", artistName: "John Sundell"),
        Podcast(trackName: "Swift Unwrapped", artistName: "JP & Jesse"),
        Podcast(trackName: "Android Developers Backstage", artistName: "Android Developers")
    ]
}
