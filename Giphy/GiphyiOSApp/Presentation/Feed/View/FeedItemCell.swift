//
//  FeedItemCell.swift
//  GiphyiOSApp
//
//  Created by Varun on 05/05/23.
//

import Foundation
import UIKit

final public class FeedItemCell: UITableViewCell {
    @IBOutlet public private(set) var feedImageView: UIImageView!
    @IBOutlet public private(set) var trendingTimeLabel: UILabel!
    @IBOutlet public private(set) var titleLabel: UILabel!
    @IBOutlet public private(set) var aurthorNameLabel: UILabel!
    
    func configure(with model: FeedListItemViewModel) {
        trendingTimeLabel.text = model.trendingDateTime
        titleLabel.text = model.title
        aurthorNameLabel.text = model.aurthorName
        model.didRequestGif()
    }
}
