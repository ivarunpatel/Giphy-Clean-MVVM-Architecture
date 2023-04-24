//
//  Giphy.swift
//  Giphy
//
//  Created by Varun on 19/04/23.
//

import Foundation

public struct Giphy: Equatable {
    public let id: String
    public let title: String
    public let datetime: String
    public let images: GiphyImages
    public let user: GiphyUser
    
    public init(id: String, title: String, datetime: String, images: GiphyImages, user: GiphyUser) {
        self.id = id
        self.title = title
        self.datetime = datetime
        self.images = images
        self.user = user
    }
}

public struct GiphyImages: Equatable {
    public let original: GiphyImageMetadata
    public let small: GiphyImageMetadata
    
    public init(original: GiphyImageMetadata, small: GiphyImageMetadata) {
        self.original = original
        self.small = small
    }
}

public struct GiphyImageMetadata: Equatable {
    public let height: String
    public let width: String
    public let url: URL
    
    public init(height: String, width: String, url: URL) {
        self.height = height
        self.width = width
        self.url = url
    }
}

public struct GiphyUser: Equatable {
    public let username: String
    public let displayName: String
    
    public init(username: String, displayName: String) {
        self.username = username
        self.displayName = displayName
    }
}

public struct GiphyPage: Equatable {
    public let totalCount: Int
    public let count: Int
    public let offset: Int
    public let giphy: [Giphy]
    
    public init(totalCount: Int, count: Int, offset: Int, giphy: [Giphy]) {
        self.totalCount = totalCount
        self.count = count
        self.offset = offset
        self.giphy = giphy
    }
}
