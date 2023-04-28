//
//  SharedTestHelpers.swift
//  GiphyTests
//
//  Created by Varun on 17/04/23.
//

import Foundation
import Giphy

func anyURL() -> URL {
    URL(string: "http://any-url.com")!
}

func anyNSError() -> NSError {
    NSError(domain: "an error", code: -1)
}

func anyData() -> Data {
    Data("any data".utf8)
}

func makeFeedItem() -> FeedPage {
    FeedPage(totalCount: 20, count: 10, offset: 0, giphy: [Feed(id: anyRandomId(), title: "title", datetime: "any time", images: FeedImages(original: FeedImageMetadata(height: "500", width: "500", url: anyURL()), small: FeedImageMetadata(height: "100", width: "100", url: anyURL())), user: FeedUser(username: "test", displayName: "test_name"))])
}

func anyRandomId() -> String {
    UUID().uuidString
}
