//
//  GiphyFeed.swift
//  Giphy
//
//  Created by Varun on 19/04/23.
//

import Foundation

public struct Feed: Equatable {
    public let id: String
    public let title: String
    public let datetime: String
    public let images: FeedImages
    public let user: FeedUser
    
    public init(id: String, title: String, datetime: String, images: FeedImages, user: FeedUser) {
        self.id = id
        self.title = title
        self.datetime = datetime
        self.images = images
        self.user = user
    }
}

public struct FeedImages: Equatable {
    public let original: FeedImageMetadata
    public let small: FeedImageMetadata
    
    public init(original: FeedImageMetadata, small: FeedImageMetadata) {
        self.original = original
        self.small = small
    }
}

public struct FeedImageMetadata: Equatable {
    public let height: String
    public let width: String
    public let url: URL
    
    public init(height: String, width: String, url: URL) {
        self.height = height
        self.width = width
        self.url = url
    }
}

public struct FeedUser: Equatable {
    public let username: String
    public let displayName: String
    
    public init(username: String, displayName: String) {
        self.username = username
        self.displayName = displayName
    }
}

public struct FeedPage: Equatable {
    public let totalCount: Int
    public let count: Int
    public let offset: Int
    public let giphy: [Feed]
    
    public init(totalCount: Int, count: Int, offset: Int, giphy: [Feed]) {
        self.totalCount = totalCount
        self.count = count
        self.offset = offset
        self.giphy = giphy
    }
}
