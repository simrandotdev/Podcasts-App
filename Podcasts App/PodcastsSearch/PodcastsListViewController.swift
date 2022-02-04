import UIKit
import Resolver
import Combine

class PodcastsSearchViewController: UITableViewController {
    
    @Injected fileprivate var searchPodcastViewModel: PodcastsListViewModel
    
    fileprivate var searchController: UISearchController?
    fileprivate let cellId = "\(PodcastCell.self)"
    fileprivate var cancellable = Set<AnyCancellable>()
    
    init() {
        super.init(nibName: nil, bundle: nil)
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
        searchPodcastViewModel
            .$podcasts
            .receive(on: DispatchQueue.main)
            .sink { _ in
                self.tableView.reloadData()
            }.store(in: &cancellable)
    }
    
    fileprivate func setupTableView() {
        let nib = UINib(nibName: "\(PodcastCell.self)", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellId)
        tableView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 40.0, right: 0)
    }
    
    fileprivate func setupSearchBar() {
        searchController = UISearchController(searchResultsController: nil)
        searchController?.obscuresBackgroundDuringPresentation = false
        searchController?.searchResultsUpdater = self
        navigationItem.searchController = searchController
    }
}


extension PodcastsSearchViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        
        guard let searchText = searchController.searchBar.text else {
            searchPodcastViewModel.searchTerm = "podcast"
            return
        }
        
        searchPodcastViewModel.searchTerm = searchText.isEmpty ? "podcast" : searchText
    }
}


// MARK:- TableView methods
extension PodcastsSearchViewController {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 116.0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchPodcastViewModel.podcasts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! PodcastCell
        cell.podcast = searchPodcastViewModel.podcast(atIndex: indexPath.row)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPodcast = searchPodcastViewModel.podcast(atIndex: indexPath.row)
        let controller = PodcastDetailsViewController()
        controller.podcastViewModel = selectedPodcast
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let activityIndicatorView = UIActivityIndicatorView(
                                        style: UIActivityIndicatorView.Style.large)
        activityIndicatorView.color = .darkGray
        activityIndicatorView.startAnimating()
        return searchPodcastViewModel.podcasts.count == 0 ? activityIndicatorView : EmptyView()
    }
}
