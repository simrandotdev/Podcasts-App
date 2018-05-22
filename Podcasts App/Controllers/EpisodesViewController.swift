import UIKit
import SDWebImage

class EpisodesViewController: UITableViewController
{
    private let cellId = "cellId"
    
    private var searchController: UISearchController?
    
    var podcast: Podcast? {
        didSet {
            navigationItem.title = podcast?.trackName
        }
    }
    
    private var episodes = [Episode]()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        setupNavigationbar()
        setupTableView()
        setupSearchBar()
        fetchEpisodes()
    }
    
    fileprivate func setupTableView()
    {
        let nib = UINib(nibName: "EpisodeCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellId)
    }
    
    fileprivate func setupSearchBar()
    {
        searchController = UISearchController(searchResultsController: nil)
        searchController?.dimsBackgroundDuringPresentation = false
        searchController?.searchBar.delegate = self
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    fileprivate func setupNavigationbar()
    {
        navigationController?.isNavigationBarHidden = false
    }
    
    fileprivate func fetchEpisodes()
    {
        guard let feedUrl = podcast?.feedUrl else { return }
        APIService.shared.fetchEpisodes(forPodcast: feedUrl) { (episodes) in
            self.episodes = episodes.items.reversed()
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
}

// MARK: TableView methods
extension EpisodesViewController
{
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return episodes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! EpisodeCell
        cell.episode = episodes[indexPath.row]
        guard let url = URL(string: podcast?.artworkUrl600 ?? "") else { return cell }
        cell.thumbnailImageView.sd_setImage(with: url, completed: nil)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let episode = episodes[indexPath.row]
        showPlayerDetailsView(withEpisode: episode)
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView?
    {
        let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicatorView.color = .darkGray
        activityIndicatorView.startAnimating()
        return activityIndicatorView
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        return episodes.isEmpty ? 200 : 0
    }
    
    fileprivate func showPlayerDetailsView(withEpisode episode: Episode)
    {
        let window = UIApplication.shared.keyWindow
        let playerDetailsView = Bundle.main.loadNibNamed("PlayerDetailsView", owner: self, options: nil)?.first as! PlayerDetailsView
        playerDetailsView.frame = self.view.frame
        playerDetailsView.episode = episode
        playerDetailsView.thumbnail = podcast?.artworkUrl600
        
        UIView.animate(withDuration: 0.72) {
            window?.addSubview(playerDetailsView)
        }
        
    }
}

// MARK: Searchbar methods
extension EpisodesViewController: UISearchBarDelegate
{
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        episodes = self.episodes.filter { (episode) -> Bool in
            (episode.title?.lowercased().contains(searchText.lowercased()))!
        }
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
    {
        
    }
}
