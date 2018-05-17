import UIKit
import Alamofire

class SearchViewController: UITableViewController, UISearchBarDelegate
{
    private var podcasts = [Podcast]()
    
    private let cellId = "cellId"
    override func viewDidLoad()
    {
        super.viewDidLoad() 
        setupTableView()
        setupSearchBar()
    }
    
    fileprivate func loadTableView(searchText: String) {
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
        let searchController = UISearchController(searchResultsController: nil)
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
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
}

// MARK: SearchBar methods
extension SearchViewController
{
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        loadTableView(searchText: searchText)
    }
}
