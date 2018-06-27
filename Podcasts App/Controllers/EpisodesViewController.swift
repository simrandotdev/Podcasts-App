import UIKit
import SDWebImage

class EpisodesViewController: UITableViewController
{
    private let cellId = "cellId"
    private var searchController: UISearchController?
    fileprivate let favoritePodcastRepository = FavoritePodcastRepository()
    
    var podcast: Podcast? {
        didSet {
            navigationItem.title = podcast?.trackName
        }
    }
    
    private var episodes = [Episode]()
    private var filtered = [Episode]()
    private var isSearching = false
    
    override
    func viewDidLoad()
    {
        super.viewDidLoad()
        
        setupNavigationbar()
        setupTableView()
        setupSearchBar()
        fetchEpisodes()
    }
    
    fileprivate
    func setupTableView()
    {
        let nib = UINib(nibName: "EpisodeCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellId)
    }
    
    fileprivate
    func setupSearchBar()
    {
        searchController = UISearchController(searchResultsController: nil)
        searchController?.dimsBackgroundDuringPresentation = false
        searchController?.searchBar.delegate = self
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    fileprivate
    func setupNavigationbar()
    {
        navigationController?.isNavigationBarHidden = false
        setupFavoriteNavigationBarItem()
    }
    
    @objc
    fileprivate
    func handleSaveToFavorites()
    {
        guard let podcast = podcast else { return }
        _ = favoritePodcastRepository.favoritePodcast(podcast: podcast)
        setupFavoriteNavigationBarItem()
    }
    
    @objc
    fileprivate
    func handleUnFavorite()
    {
        guard let podcast = podcast else { return }
        _ = favoritePodcastRepository.unfavoritePodcast(podcast: podcast)
        setupFavoriteNavigationBarItem()
    }
    
    fileprivate
    func setupFavoriteNavigationBarItem()
    {
        guard let podcast = podcast else { return }
        if (favoritePodcastRepository.isFavorite(podcast: podcast)) {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Unfavorite", style: .plain, target: self, action: #selector(handleUnFavorite))
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Favorite", style: .plain, target: self, action: #selector(handleSaveToFavorites))
        }
    }
    
    
    fileprivate
    func fetchEpisodes()
    {
        guard let feedUrl = podcast?.feedUrl else { return }
        APIService.shared.fetchEpisodes(forPodcast: feedUrl) { (episodes) in
            self.episodes = episodes.items.reversed()
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
}

// MARK: TableView methods
extension EpisodesViewController
{
    override
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return UITableView.automaticDimension
    }
    
    override
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return isSearching ? filtered.count : episodes.count
    }
    
    override
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! EpisodeCell
        cell.episode = isSearching ? filtered[indexPath.row] : episodes[indexPath.row]
        guard let url = URL(string: podcast?.artworkUrl600 ?? "") else { return cell }
        cell.thumbnailImageView.sd_setImage(with: url, completed: nil)
        return cell
    }
    
    override
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        var episode = isSearching ? filtered[indexPath.row] : episodes[indexPath.row]
        episode.imageUrl = podcast?.artworkUrl600
        let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController
        mainTabBarController?.maximizePlayerDetails(episode: episode, playListEpisodes: self.episodes)
        
    }
    
    override
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView?
    {
        let activityIndicatorView = UIActivityIndicatorView(style: .whiteLarge)
        activityIndicatorView.color = .darkGray
        activityIndicatorView.startAnimating()
        return activityIndicatorView
    }
    
    override
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        return episodes.isEmpty ? 200 : 0
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        var episode = self.episodes[indexPath.row]
        episode.imageUrl = podcast?.artworkUrl600
        let downloadAction = UITableViewRowAction(style: .normal, title: "Download") { (_, _) in
            print("Downloading episodes into UserDefaults")
            self.favoritePodcastRepository.downloadEpisode(episode: episode)
        }
        return [downloadAction]
    }
    
    fileprivate
    func showPlayerDetailsView(withEpisode episode: Episode)
    {
        let window = UIApplication.shared.keyWindow
        let playerDetailsView = PlayerDetailsView.initFromNib()
        playerDetailsView.frame = self.view.frame
        playerDetailsView.episode = episode
        playerDetailsView.thumbnail = podcast?.artworkUrl600
        
        UIView.animate(withDuration: 0.72) {
            window?.addSubview(playerDetailsView)
        }
    }
}

// MARK: Searchbar methods
extension EpisodesViewController: UISearchBarDelegate
{
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        isSearching = searchText.count > 0
        
        filtered = self.episodes.filter { (episode) -> Bool in
            (episode.title?.lowercased().contains(searchText.lowercased())) ?? false
        }
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
    {
        isSearching = false
    }
}
