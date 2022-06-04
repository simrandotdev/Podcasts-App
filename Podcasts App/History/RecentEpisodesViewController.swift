import UIKit
import SDWebImage
import Resolver

class RecentEpisodesViewController: UITableViewController {
    private let cellId = "cellId"
    private var searchController: UISearchController?
    
    var maximizePlayer: ((EpisodeViewModel?, [EpisodeViewModel]?) -> Void)?
    
    @Injected fileprivate var episodesListViewModel: RecentEpisodesListViewModel
    
    init() { super.init(nibName: nil, bundle: nil) }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        tableView.backgroundColor = Theme.Color.systemBackgroundColor
        tableView.separatorStyle = .none
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
        episodesListViewModel.fetchEpisodes()
        tableView.reloadData()
    }
}

// MARK: TableView methods
extension RecentEpisodesViewController {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110.0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodesListViewModel.episodesList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! EpisodeCell
        cell.episode = episodesListViewModel.episodesList[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let episode = episodesListViewModel.episodesList[indexPath.row]
        maximizePlayer?(episode, self.episodesListViewModel.episodesList)
        
    }
}

// MARK: Searchbar methods
extension RecentEpisodesViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        episodesListViewModel.search(forValue: searchText)
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        episodesListViewModel.finishSearch()
    }
}
