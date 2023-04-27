//
//  GiphyFeed.swift
//  Giphy
//
//  Created by Varun on 19/04/23.
//

import Foundation

public struct GiphyFeed: Equatable {
    public let id: String
    public let title: String
    public let datetime: String
    public let images: GiphyFeedImages
    public let user: GiphyFeedUser
    
    public init(id: String, title: String, datetime: String, images: GiphyFeedImages, user: GiphyFeedUser) {
        self.id = id
        self.title = title
        self.datetime = datetime
        self.images = images
        self.user = user
    }
}

public struct GiphyFeedImages: Equatable {
    public let original: GiphyFeedImageMetadata
    public let small: GiphyFeedImageMetadata
    
    public init(original: GiphyFeedImageMetadata, small: GiphyFeedImageMetadata) {
        self.original = original
        self.small = small
    }
}

public struct GiphyFeedImageMetadata: Equatable {
    public let height: String
    public let width: String
    public let url: URL
    
    public init(height: String, width: String, url: URL) {
        self.height = height
        self.width = width
        self.url = url
    }
}

public struct GiphyFeedUser: Equatable {
    public let username: String
    public let displayName: String
    
    public init(username: String, displayName: String) {
        self.username = username
        self.displayName = displayName
    }
}

public struct GiphyFeedPage: Equatable {
    public let totalCount: Int
    public let count: Int
    public let offset: Int
    public let giphy: [GiphyFeed]
    
    public init(totalCount: Int, count: Int, offset: Int, giphy: [GiphyFeed]) {
        self.totalCount = totalCount
        self.count = count
        self.offset = offset
        self.giphy = giphy
    }
}
