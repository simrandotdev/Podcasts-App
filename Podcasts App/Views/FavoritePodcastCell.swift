import UIKit

class FavoritePodcastCell : UICollectionViewCell
{
   
    override
    init(frame: CGRect)
    {
        super.init(frame: frame)
        stylizeUI()
        layoutUI()
        
        backgroundColor = primaryLightColor
        layer.cornerRadius = 2.0
        layer.masksToBounds = true
    }
    
    required
    init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK:- Setups
    fileprivate
    func stylizeUI()
    {
        nameLabel.text = ""
        nameLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = .white
        nameLabel.numberOfLines = 2
        artistNameLabel.text = ""
        artistNameLabel.font = UIFont.systemFont(ofSize: 13)
        artistNameLabel.textColor = .white
        imageView.contentMode = UIView.ContentMode.center
        
    }
    
    fileprivate
    func layoutUI()
    {
        addSubview(imageView)
        imageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        let backgroundView: UIView = {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
            return view
        }()
        addSubview(backgroundView)
        backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        backgroundView.heightAnchor.constraint(equalToConstant: 70).isActive = true

        let stackView = UIStackView(arrangedSubviews: [nameLabel, artistNameLabel])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fill
        
        backgroundView.addSubview(stackView)
        stackView.topAnchor.constraint(equalTo: backgroundView.topAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 8).isActive = true
        stackView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -8).isActive = true
        stackView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -8).isActive = true
    }
    
    
    func setupCell(podcast: Podcast)
    {
        guard let imageUrl = URL(string: podcast.artworkUrl600 ?? "") else { return }
        imageView.sd_setImage(with: imageUrl)
        nameLabel.text = podcast.trackName
        artistNameLabel.text = podcast.artistName
    }
    
    // MARK:- UI properties
    let imageView = UIImageView(image: UIImage(named: "appicon"))
    let nameLabel = UILabel()
    let artistNameLabel = UILabel()
}
