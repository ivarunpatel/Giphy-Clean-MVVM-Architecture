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
}

public struct GiphyImages: Equatable {
    let original: GiphyImageMetadata
    let small: GiphyImageMetadata
}

public struct GiphyImageMetadata: Equatable {
    let height: String
    let width: String
    let url: URL
}

public struct GiphyPage: Equatable {
    let totalCount: Int
    let count: Int
    let offset: Int
    let giphy: [Giphy]
}
