//
//  FeedItemCell.swift
//  GiphyiOSApp
//
//  Created by Varun on 05/05/23.
//

import Foundation
import UIKit

final public class FeedItemCell: UITableViewCell {
    public let feedImageView: UIImageView = UIImageView()
    public let trendingTimeLabel: UILabel = UILabel()
    public let titleLabel: UILabel = UILabel()
    public let aurthorNameLabel: UILabel = UILabel()
    
    func configure(with model: FeedListItemViewModel) {
        trendingTimeLabel.text = model.trendingDateTime
        titleLabel.text = model.title
        aurthorNameLabel.text = model.aurthorName
        model.didRequestGif()
    }
}
