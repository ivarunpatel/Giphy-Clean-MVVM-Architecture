//
//  FeedListItemViewModel.swift
//  GiphyiOSApp
//
//  Created by Varun on 01/05/23.
//

import Foundation
import Giphy

public struct FeedListItemViewModel: Equatable {
    public let id: String
    public let title: String
    public private(set) var datetime: String?
    public let images: FeedImages
    public let user: FeedUser?
    
    public init(feed: Feed) {
        id = feed.id
        title = feed.title
        images = feed.images
        user = feed.user
        datetime = formatDateTime(datetime: feed.datetime)
    }
    
    private func formatDateTime(datetime: String?) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        if let dateTimeString = datetime,
           let date = dateFromString(dateTime: dateTimeString) {
            return formatter.localizedString(for: date, relativeTo: Date())
        } else {
            return ""
        }
    }
    
    private func dateFromString(dateTime: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        return dateFormatter.date(from: dateTime)
    }
}
