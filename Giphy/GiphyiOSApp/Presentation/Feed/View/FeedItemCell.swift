//
//  FeedItemCell.swift
//  GiphyiOSApp
//
//  Created by Varun on 05/05/23.
//

import Foundation
import UIKit

final public class FeedItemCell: UITableViewCell {
    @IBOutlet private(set) public var feedImageView: UIImageView!
    @IBOutlet private(set) public var trendingTimeLabel: UILabel!
    @IBOutlet private(set) public var titleLabel: UILabel!
    @IBOutlet private(set) public var aurthorNameLabel: UILabel!
    
    public override func awakeFromNib() {
        setupUI()
    }
    
    public override func prepareForReuse() {
        feedImageView.image = nil
    }
    
    private func setupUI() {
        feedImageView.layer.cornerRadius = 10
    }
    
    func configure(with model: FeedListItemViewModel) {
        trendingTimeLabel.text = model.trendingDateTime
        titleLabel.text = model.title
        aurthorNameLabel.text = model.aurthorName
        model.didRequestGif()
        
        model.gifData = { data in
            guaranteeMainThread { [weak self] in
                guard let self = self else { return }
                feedImageView.image = UIImage.gifImageWithData(data)
            }
        }
    }
}
