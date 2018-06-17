import Foundation

class Podcast : NSObject, Codable, NSCoding
{
    func encode(with aCoder: NSCoder)
    {
        aCoder.encode(trackName ?? "", forKey: "trackName")
        aCoder.encode(artistName ?? "", forKey: "artistName")
        aCoder.encode(artworkUrl600 ?? "", forKey: "artworkUrl600")
        aCoder.encode(trackCount ?? "", forKey: "trackCount")
        aCoder.encode(feedUrl ?? "", forKey: "feedUrl")
    }
    
    required
    init?(coder aDecoder: NSCoder)
    {
        self.trackName = aDecoder.decodeObject(forKey: "trackName") as? String
        self.artistName = aDecoder.decodeObject(forKey: "artistName") as? String
        self.artworkUrl600 = aDecoder.decodeObject(forKey: "artworkUrl600") as? String
        self.trackCount = aDecoder.decodeObject(forKey: "trackCount") as? Int
        self.feedUrl = aDecoder.decodeObject(forKey: "feedUrl") as? String
    }
    
    var trackName: String?
    var artistName: String?
    var artworkUrl600: String?
    var trackCount: Int?
    var feedUrl: String?
    
    override func isEqual(_ object: Any?) -> Bool {
        let pod = object as? Podcast
        
        return pod?.artistName == self.artistName &&
            pod?.artworkUrl600 ?? "" == self.artworkUrl600 &&
            pod?.trackName ?? "" == self.trackName &&
            pod?.trackCount ?? 0 == self.trackCount &&
            pod?.feedUrl ?? "" == self.feedUrl
        
    }
}
