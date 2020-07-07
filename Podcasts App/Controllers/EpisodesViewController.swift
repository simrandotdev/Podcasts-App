import UIKit
import SDWebImage

class EpisodesViewController: UITableViewController
{
    private let cellId = "cellId"
    private var searchController: UISearchController?
    fileprivate let repo = PodcastsRepository()
    
    var podcast: Podcast? {
        didSet {
            navigationItem.title = podcast?.title
        }
    }
    
    private var episodes = [Episode]()
    private var filtered = [Episode]()
    private var isSearching = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationbar()
        setupTableView()
        setupSearchBar()
        fetchEpisodes()
    }
    
    fileprivate func setupTableView() {
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 40.0, right: 0)
        let nib = UINib(nibName: "EpisodeCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellId)
    }
    
    fileprivate func setupSearchBar() {
        searchController = UISearchController(searchResultsController: nil)
        searchController?.searchBar.delegate = self
        searchController?.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    fileprivate func setupNavigationbar() {
        navigationController?.isNavigationBarHidden = false
        setupFavoriteNavigationBarItem()
    }
    
    @objc fileprivate func handleSaveToFavorites() {
        guard let podcast = podcast else { return }
        _ = repo.favoritePodcast(podcast: podcast)
        setupFavoriteNavigationBarItem()
    }
    
    @objc fileprivate func handleUnFavorite() {
        guard let podcast = podcast else { return }
        _ = repo.unfavoritePodcast(podcast: podcast)
        setupFavoriteNavigationBarItem()
    }
    
    fileprivate func setupFavoriteNavigationBarItem() {
        guard let podcast = podcast else { return }
        if (repo.isFavorite(podcast: podcast)) {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "heart.fill"), style: .plain, target: self, action: #selector(handleUnFavorite))
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "heart"), style: .plain, target: self, action: #selector(handleSaveToFavorites))
        }
    }
    
    
    fileprivate func fetchEpisodes() {
        guard let feedUrl = podcast?.rssFeedUrl else { return }
        APIService.shared.fetchEpisodes(forPodcast: feedUrl) { (episodes) in
            self.episodes = episodes
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
}

// MARK: TableView methods
extension EpisodesViewController {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { return 110.0 }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return isSearching ? filtered.count : episodes.count }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! EpisodeCell
        cell.episode = isSearching ? filtered[indexPath.row] : episodes[indexPath.row]
        guard let url = URL(string: podcast?.image ?? "") else { return cell }
        cell.thumbnailImageView.sd_setImage(with: url, completed: nil)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var episode = isSearching ? filtered[indexPath.row] : episodes[indexPath.row]
        episode.imageUrl = podcast?.image
        self.view.window?.endEditing(true)
        let mainTabBarController = UIApplication.shared.windows.first?.rootViewController as? MainTabBarController
        mainTabBarController?.maximizePlayerDetails(episode: episode, playListEpisodes: self.episodes)
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let activityIndicatorView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        activityIndicatorView.color = .darkGray
        activityIndicatorView.startAnimating()
        return activityIndicatorView
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return episodes.isEmpty ? 200 : 0
    }
}

// MARK: Searchbar methods
extension EpisodesViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        isSearching = searchText.count > 0
        
        filtered = self.episodes.filter { (episode) -> Bool in
            (episode.title.lowercased().contains(searchText.lowercased())) 
        }
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearching = false
    }
}
