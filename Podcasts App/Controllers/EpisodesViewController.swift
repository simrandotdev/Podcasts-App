import UIKit
import SDWebImage

class EpisodesViewController: UITableViewController
{
    private let cellId = "cellId"
    private var searchController: UISearchController?

    fileprivate var episodesListViewModel: EpisodesListViewModel!
    
    var podcastViewModel: PodcastViewModel? {
        didSet {
            navigationItem.title = podcastViewModel?.title
        }
    }
    
    init(episodesListViewModel: EpisodesListViewModel = EpisodesListViewModel()) {
        super.init(nibName: nil, bundle: nil)
        self.episodesListViewModel = episodesListViewModel
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationbar()
        setupTableView()
        setupSearchBar()
        guard let podcastViewModel = podcastViewModel else { return }
        episodesListViewModel.delegate = self
        episodesListViewModel.fetchEpisodes(forPodcast: podcastViewModel)
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
        podcastViewModel?.favorite()
        setupFavoriteNavigationBarItem()
    }
    
    @objc fileprivate func handleUnFavorite() {
        podcastViewModel?.unfavorite()
        setupFavoriteNavigationBarItem()
    }
    
    fileprivate func setupFavoriteNavigationBarItem() {
        if podcastViewModel?.isFavorite() ?? false {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "heart.fill"), style: .plain, target: self, action: #selector(handleUnFavorite))
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "heart"), style: .plain, target: self, action: #selector(handleSaveToFavorites))
        }
    }
}

// MARK: TableView methods
extension EpisodesViewController {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { return 110.0 }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodesListViewModel.episodesList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! EpisodeCell
        cell.episode = self.episodesListViewModel.episode(atIndex: indexPath.row)
        guard let url = URL(string: podcastViewModel?.image ?? "") else { return cell }
        cell.thumbnailImageView.sd_setImage(with: url, completed: nil)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let episode = self.episodesListViewModel.episode(atIndex: indexPath.row)
        episode.imageUrl = podcastViewModel?.image
        self.view.window?.endEditing(true)
        let mainTabBarController = UIApplication.shared.windows.first?.rootViewController as? MainTabBarController
        mainTabBarController?.maximizePlayerDetails(episode: episode, playListEpisodes: episodesListViewModel.episodesList)
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let activityIndicatorView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        activityIndicatorView.color = .darkGray
        activityIndicatorView.startAnimating()
        return activityIndicatorView
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return episodesListViewModel.episodesList.isEmpty ? 200 : 0
    }
}

// MARK: Searchbar methods
extension EpisodesViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        episodesListViewModel.search(forValue: searchText)
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        episodesListViewModel.finishSearch()
    }
}

// MARK: EpisodesListViewModel Protocol
extension EpisodesViewController : EpisodesListViewModelProtocol {
    func didFetchedEpisodes() {
        tableView.reloadData()
    }
}
