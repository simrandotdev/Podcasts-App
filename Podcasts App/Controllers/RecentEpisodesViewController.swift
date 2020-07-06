import UIKit
import SDWebImage

class RecentEpisodesViewController: UITableViewController {
    private let cellId = "cellId"
    private var searchController: UISearchController?
    fileprivate let repo = PodcastsRepository()
    
    
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
    }
    
    
    fileprivate func fetchEpisodes() {
        episodes = repo.fetchAllRecentlyPlayedPodcasts() ?? episodes
        tableView.reloadData()
    }
}

// MARK: TableView methods
extension RecentEpisodesViewController {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110.0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? filtered.count : episodes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! EpisodeCell
        cell.episode = isSearching ? filtered[indexPath.row] : episodes[indexPath.row]
        guard let url = URL(string: cell.episode.imageUrl ?? "") else { return cell }
        cell.thumbnailImageView.sd_setImage(with: url, completed: nil)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let episode = isSearching ? filtered[indexPath.row] : episodes[indexPath.row]
        let mainTabBarController = UIApplication.shared.windows.first?.rootViewController as? MainTabBarController
        mainTabBarController?.maximizePlayerDetails(episode: episode, playListEpisodes: self.episodes)
        
    }
}

// MARK: Searchbar methods
extension RecentEpisodesViewController: UISearchBarDelegate {
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
