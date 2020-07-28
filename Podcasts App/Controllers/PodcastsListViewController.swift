import UIKit

class PodcastsListViewController: UITableViewController {
    fileprivate var searchPodcastViewModel: PodcastsListViewModel!
    fileprivate var searchController: UISearchController?
    fileprivate let cellId = "cellId"
    
    init(searchPodcastViewModel: PodcastsListViewModel = PodcastsListViewModel()) {
        super.init(nibName: nil, bundle: nil)
        self.searchPodcastViewModel = searchPodcastViewModel
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupSearchBar()
        setupSearchPodcastViewModel()
    }
    
    // MARK:- Helper methods
    fileprivate func setupSearchPodcastViewModel() {
        searchPodcastViewModel.delegate = self
        searchPodcastViewModel.fetchPodcasts()
    }
    
    fileprivate func setupTableView() {
        let nib = UINib(nibName: "PodcastCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellId)
        tableView.separatorStyle = .none
        tableView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 40.0, right: 0)
    }
    
    fileprivate func setupSearchBar() {
        searchController = UISearchController(searchResultsController: nil)
        searchController?.obscuresBackgroundDuringPresentation = false
        searchController?.searchBar.delegate = self
        navigationItem.searchController = searchController
    }
}

// MARK:- TableView methods
extension PodcastsListViewController {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100.0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchPodcastViewModel.numberOfPodcasts
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! PodcastCell
        cell.podcast = searchPodcastViewModel.podcast(atIndex: indexPath.row)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPodcast = searchPodcastViewModel.podcast(atIndex: indexPath.row)
        let controller = EpisodesViewController()
        controller.podcastViewModel = selectedPodcast
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let activityIndicatorView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        activityIndicatorView.color = .darkGray
        activityIndicatorView.startAnimating()
        return searchPodcastViewModel.numberOfPodcasts == 0 ? activityIndicatorView : UIView()
    }
}

// MARK:- SearchBar methods
extension PodcastsListViewController : UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchPodcastViewModel.searchPodcasts(podcast: searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchPodcastViewModel.fetchPodcasts()
    }
}

// MARK:- SearchPodcastViewModelDelegate
extension PodcastsListViewController : PodcastsListViewModelDelegate {
    func didFetchedPodcasts() {
        tableView.reloadData()
    }
}
