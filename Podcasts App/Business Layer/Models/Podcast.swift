import Foundation

class Podcast : NSObject, Codable, NSCoding {
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(title ?? "", forKey: "title")
        aCoder.encode(author ?? "", forKey: "author")
        aCoder.encode(image ?? "", forKey: "image")
        aCoder.encode(totalEpisodes ?? "", forKey: "totalEpisodes")
        aCoder.encode(rssFeedUrl ?? "", forKey: "rssFeedUrl")
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.title = aDecoder.decodeObject(forKey: "title") as? String
        self.author = aDecoder.decodeObject(forKey: "author") as? String
        self.image = aDecoder.decodeObject(forKey: "image") as? String
        self.totalEpisodes = aDecoder.decodeObject(forKey: "totalEpisodes") as? Int
        self.rssFeedUrl = aDecoder.decodeObject(forKey: "rssFeedUrl") as? String
    }
    
    init(podcastViewModel: PodcastViewModel) {
        self.title = podcastViewModel.title
        self.author = podcastViewModel.author
        self.image = podcastViewModel.image
        self.totalEpisodes = Int(podcastViewModel.numberOfEpisodes) ?? 0
        self.rssFeedUrl = podcastViewModel.rssFeedUrl
        self.recordId = podcastViewModel.recordId
    }
    
    init(recordId: String, title: String, author: String, image: String, totalEpisodes: Int, rssFeedUrl: String) {
        self.recordId = recordId
        self.title = title
        self.author = author
        self.image = image
        self.totalEpisodes = totalEpisodes
        self.rssFeedUrl = rssFeedUrl
    }
    
    var recordId: String?
    var title: String?
    var author: String?
    var image: String?
    var totalEpisodes: Int?
    var rssFeedUrl: String?
    
    override func isEqual(_ object: Any?) -> Bool {
        let pod = object as? Podcast
        
        return pod?.author == self.author &&
            pod?.image ?? "" == self.image &&
            pod?.title ?? "" == self.title &&
            pod?.totalEpisodes ?? 0 == self.totalEpisodes &&
            pod?.rssFeedUrl ?? "" == self.rssFeedUrl
        
    }
}
