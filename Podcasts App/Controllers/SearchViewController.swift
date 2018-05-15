import UIKit

class SearchViewController: UITableViewController, UISearchBarDelegate
{
    private let podcasts = Podcast.mockPodcasts
    
    private let cellId = "cellId"
    override func viewDidLoad()
    {
        super.viewDidLoad() 
        setupTableView()
        setupSearchBar()
    }
    
    fileprivate func setupTableView()
    {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
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
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return podcasts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        var cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        let podcast = podcasts[indexPath.row]
        setupCell(cell: &cell, index: indexPath.row, podcast: podcast)
        return cell
    }
    
    fileprivate func setupCell( cell: inout UITableViewCell, index: Int, podcast: Podcast)
    {
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = "\(podcast.name)\n\(podcast.artistName)"
        cell.imageView?.image = #imageLiteral(resourceName: "appicon")
    }
}

// MARK: SearchBar methods
extension SearchViewController
{
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        print(searchText)
    }
}
