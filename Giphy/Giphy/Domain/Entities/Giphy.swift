//
//  Giphy.swift
//  Giphy
//
//  Created by Varun on 19/04/23.
//

import Foundation

public struct Giphy: Equatable {
    let id: String
    let title: String
    let datetime: String
    let images: GiphyImages
    let user: GiphyUser
    
    public init(id: String, title: String, datetime: String, images: GiphyImages, user: GiphyUser) {
        self.id = id
        self.title = title
        self.datetime = datetime
        self.images = images
        self.user = user
    }
}

public struct GiphyImages: Equatable {
    let original: GiphyImageMetadata
    let small: GiphyImageMetadata
    
    public init(original: GiphyImageMetadata, small: GiphyImageMetadata) {
        self.original = original
        self.small = small
    }
}

public struct GiphyImageMetadata: Equatable {
    let height: String
    let width: String
    let url: URL
    
    public init(height: String, width: String, url: URL) {
        self.height = height
        self.width = width
        self.url = url
    }
}

public struct GiphyUser: Equatable {
    let username: String
    let displayName: String
    
    public init(username: String, displayName: String) {
        self.username = username
        self.displayName = displayName
    }
}

public struct GiphyPage: Equatable {
    let totalCount: Int
    let count: Int
    let offset: Int
    let giphy: [Giphy]
    
    public init(totalCount: Int, count: Int, offset: Int, giphy: [Giphy]) {
        self.totalCount = totalCount
        self.count = count
        self.offset = offset
        self.giphy = giphy
    }
}
