import UIKit
import Alamofire

class SearchViewController: UITableViewController
{
    private var podcasts = [Podcast]()
    private var searchController: UISearchController?
    fileprivate var timer : Timer?
    
    private let cellId = "cellId"
    override func viewDidLoad()
    {
        super.viewDidLoad() 
        setupTableView()
        setupSearchBar()
        #if DEBUG
        searchBar((searchController?.searchBar)!, textDidChange: "Fragmented Podcast")
        #endif
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        reSetupSearchbar()
    }
    
    fileprivate func loadTableView(searchText: String)
    {
        APIService.shared.fetchPodcast(searchText: searchText) { (podcasts) in
            DispatchQueue.main.async {
                self.podcasts = podcasts
                self.tableView.reloadData()
            }
        }
    }
    
    fileprivate func setupTableView()
    {
        let nib = UINib(nibName: "PodcastCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellId)
        
        loadTableView(searchText: "podcast")
    }
    
    fileprivate func setupSearchBar()
    {
        searchController = UISearchController(searchResultsController: nil)
        searchController?.dimsBackgroundDuringPresentation = false
        searchController?.searchBar.delegate = self
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    fileprivate func reSetupSearchbar()
    {
        let previousText = searchController?.searchBar.text
        setupSearchBar()
        searchController?.searchBar.text = previousText
    }
}

// MARK:- TableView methods
extension SearchViewController
{
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return podcasts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! PodcastCell
        cell.podcast = podcasts[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let selectedPodcast = podcasts[indexPath.row]
        let controller = EpisodesViewController()
        controller.podcast = selectedPodcast
        self.navigationController?.pushViewController(controller, animated: true)
    }
}

// MARK: SearchBar methods
extension SearchViewController : UISearchBarDelegate
{
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false, block: { (_) in
            self.loadTableView(searchText: searchText)
        })
        
    }
}
