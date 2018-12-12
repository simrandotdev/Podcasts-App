import UIKit

class DownloadViewController: UITableViewController
{
    fileprivate let cellId = "cellId"
    fileprivate let favoritePodcastRepository = FavoritePodcastRepository()
    fileprivate var episodes = [Episode]()
    
    override
    func viewDidLoad()
    {
        super.viewDidLoad()
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        loadDataIntoTableView()
    }
    
    
    // MARK: Setup
    fileprivate
    func setupTableView()
    {
        let nib = UINib(nibName: "EpisodeCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellId)
    }
    
    fileprivate
    func loadDataIntoTableView()
    {
        episodes = favoritePodcastRepository.downloadedEpisodes()
        tableView.reloadData()
    }
}

// MARK: TableView
extension DownloadViewController
{
    override
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return episodes.count
    }
    
    override
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! EpisodeCell
        let episode = episodes[indexPath.row]
        cell.episode = episode
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 120
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        let downloadAction = UITableViewRowAction(style: .destructive, title: "Delete") { (_, _) in
            print("Deleting episodes from UserDefaults")
            self.favoritePodcastRepository.deleteEpisode(at: indexPath.row)
            self.loadDataIntoTableView()
        }
        return [downloadAction]
    }
    
}
