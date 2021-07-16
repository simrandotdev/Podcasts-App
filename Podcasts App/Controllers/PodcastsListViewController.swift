import UIKit
import RxSwift
import RxCocoa

class PodcastsListViewController: UITableViewController {
    fileprivate var searchPodcastViewModel: PodcastsListViewModel!
    fileprivate var searchController: UISearchController?
    fileprivate let cellId = "\(PodcastCell.self)"
    
    fileprivate let disposeBag = DisposeBag()
    
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
        searchPodcastViewModel
            .podcastsObserver
            .subscribe(onNext: { podcasts in
                DispatchQueue.main.async {
                    self.tableView.reloadData() 
                }
            }).disposed(by: disposeBag)
            
    }
    
    fileprivate func setupTableView() {
        let nib = UINib(nibName: "\(PodcastCell.self)", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellId)
        tableView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 40.0, right: 0)
    }
    
    fileprivate func setupSearchBar() {
        searchController = UISearchController(searchResultsController: nil)
        searchController?.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
        
        searchController?.searchBar
            .rx
            .text
            .ifEmpty(default: "podcasts")
            .throttle(RxTimeInterval.milliseconds(750) , scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(onNext: { input in
                guard let searchText = input?.description else { return }
                self.searchPodcastViewModel.fetchPodcastsObservable(query: searchText)
            }).disposed(by: disposeBag)
        
        searchController?.searchBar
            .rx
            .cancelButtonClicked
            .subscribe(onNext: {
                self.searchPodcastViewModel.fetchPodcastsObservable(query: "podcasts")
            }).disposed(by: disposeBag)
        
    }
}

// MARK:- TableView methods
extension PodcastsListViewController {
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
        let controller = EpisodesViewController()
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
