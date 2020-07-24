import UIKit

class SearchViewController: UITableViewController {
    fileprivate var searchPodcastViewModel: SearchPodcastViewModel!
    fileprivate var searchController: UISearchController?
    fileprivate var timer : Timer?
    fileprivate let cellId = "cellId"
    
    init(searchPodcastViewModel: SearchPodcastViewModel = SearchPodcastViewModel()) {
        super.init(nibName: nil, bundle: nil)
        self.searchPodcastViewModel = searchPodcastViewModel
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        setupTableView()
        setupSearchBar()
        setupSearchPodcastViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchController?.searchBar.text = searchPodcastViewModel.searchTerm
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        searchController?.isActive = false
    }
    
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
        self.definesPresentationContext = true
        searchController = UISearchController(searchResultsController: nil)
        searchController?.obscuresBackgroundDuringPresentation = false
        searchController?.searchBar.delegate = self
        searchController?.searchBar.text = searchPodcastViewModel.searchTerm
        searchController?.definesPresentationContext = true
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
}

// MARK:- TableView methods
extension SearchViewController {
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
}

// MARK: SearchBar methods
extension SearchViewController : UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchPodcastViewModel.searchPodcasts(podcast: searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchPodcastViewModel.fetchPodcasts(query: "podcast")
    }
}

// MARK: SearchPodcastViewModelDelegate
extension SearchViewController : SearchPodcastViewModelDelegate {
    func didFetchedPodcasts() {
        tableView.reloadData()
    }
}
