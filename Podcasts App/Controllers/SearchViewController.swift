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
        let url = "https://itunes.apple.com/search?term=Android"
        searchPodcast(url, searchText: "Android")
    }
    
    fileprivate func setupTableView()
    {
//        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
        let nib = UINib(nibName: "PodcastCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellId)
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
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
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
        APIService.shared.fetchPodcast(searchText: searchText) { (podcasts) in
            self.podcasts = podcasts
            self.tableView.reloadData()
        }
    }
    
    fileprivate func searchPodcast(_ url: String, searchText: String) {
        let parameters = ["term": searchText, "media": "podcast"]
        
        Alamofire.request(url, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: nil)
            .responseData { (dataResponse) in
            if let err = dataResponse.error
            {
                print("Failed to contact yahoo", err)
                return
            }
            
            guard let data = dataResponse.data else { return }
            
            do
            {
                let searchResults = try JSONDecoder().decode(SearchResults.self, from: data)
                self.podcasts = searchResults.results
                self.tableView.reloadData()
            } catch let decodeErr {
                print("Failed to decode: ", decodeErr)
            }
        }
    }
}
