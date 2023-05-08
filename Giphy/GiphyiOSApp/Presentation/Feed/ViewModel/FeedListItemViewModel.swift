//
//  FeedListItemViewModel.swift
//  GiphyiOSApp
//
//  Created by Varun on 01/05/23.
//

import Foundation
import Giphy

public class FeedListItemViewModel {
    private let gifDataRepository: GifDataRepository
    public let id: String
    public let title: String
    public private(set) var trendingDateTime: String?
    public let images: FeedImages
    public private(set) var aurthorName: String?
    public var gifData: ((Data) -> Void)?
    
    public init(feed: Feed, gifDataRepository: GifDataRepository) {
        self.gifDataRepository = gifDataRepository
        id = feed.id
        title = feed.title
        images = feed.images
        aurthorName = setAurthorName(user: feed.user)
        trendingDateTime = formatTrendingDateTime(datetime: feed.datetime)
    }
    
    var gifDataRepositoryCancallable: Cancellable?
    
    private func formatTrendingDateTime(datetime: String?) -> String? {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        if let dateTimeString = datetime,
           let date = dateFromString(dateTime: dateTimeString) {
            let formattedDateTime = formatter.localizedString(for: date, relativeTo: Date())
            let displayDateTime = "Trending on: \(formattedDateTime)"
            return displayDateTime
        } else {
            return nil
        }
    }
    
    private func setAurthorName(user: FeedUser?) -> String? {
        if let displayName = user?.displayName {
            return "Aurthor: \(displayName)"
        } else {
            return nil
        }
    }
    
    private func dateFromString(dateTime: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        return dateFormatter.date(from: dateTime)
    }
    
    public func didRequestGif() {
        let gifURL = images.small.url
        gifDataRepositoryCancallable = gifDataRepository.fetchGif(url: gifURL.absoluteString, completion: { [weak self] result in
            guard let self = self else { return }
            if let data = try? result.get() {
                gifData?(data)
            }
        })
    }
    
    public func didCancelGifRequest() {
        gifDataRepositoryCancallable?.cancel()
        gifDataRepositoryCancallable = nil
        gifData = nil
    }
}

extension FeedListItemViewModel: Equatable {
    public static func == (lhs: FeedListItemViewModel, rhs: FeedListItemViewModel) -> Bool {
        lhs.id == rhs.id
    }
}
