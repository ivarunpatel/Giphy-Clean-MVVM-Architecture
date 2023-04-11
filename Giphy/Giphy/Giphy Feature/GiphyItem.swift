//
//  GiphyItem.swift
//  Giphy
//
//  Created by Varun on 11/04/23.
//

import Foundation

struct GiphyItem {
    public let id: String
    public let title: String
    public let dateTime: String
    public let images: [GiphyImage]
    
    public init(id: String, title: String, dateTime: String, images: [GiphyImage]) {
        self.id = id
        self.title = title
        self.dateTime = dateTime
        self.images = images
    }
}

struct GiphyImage {
    public let original: GiphyImageMetadata
    public let small: GiphyImageMetadata
    
    public init(original: GiphyImageMetadata, small: GiphyImageMetadata) {
        self.original = original
        self.small = small
    }
}

struct GiphyImageMetadata {
    public let height: Int
    public let width: Int
    public let url: URL
    
    public init(height: Int, width: Int, url: URL) {
        self.height = height
        self.width = width
        self.url = url
    }
}
