import UIKit

class EpisodesViewController: UITableViewController
{
    private let cellId = "cellId"
    
    var podcast: Podcast? {
        didSet {
            navigationItem.title = podcast?.trackName
        }
    }
    
    private var episodes = [Episode]()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        setupTableView()
        fetchEpisodes()
    }
    
    fileprivate func setupTableView()
    {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
    }
    
    fileprivate func fetchEpisodes()
    {
        guard let feedUrl = podcast?.feedUrl else { return }
        APIService.shared.fetchEpisodes(forPodcast: feedUrl) { (episodes) in
            self.episodes = episodes.items
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
}

// MARK: TableView methods
extension EpisodesViewController
{
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 60.0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return episodes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        let episode = episodes[indexPath.row]
        cell.textLabel?.text = "\(episode.title)"
        return cell
    }
}
