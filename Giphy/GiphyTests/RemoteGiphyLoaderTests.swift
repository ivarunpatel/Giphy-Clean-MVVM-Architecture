//
//  RemoteGiphyLoaderTests.swift
//  GiphyTests
//
//  Created by Varun on 11/04/23.
//

import XCTest

class RemoteGiphyLoader {
    
}

class HTTPClient {
    var requestedURL: String?
}

final class RemoteGiphyLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClient()
        _ = RemoteGiphyLoader()
        
        XCTAssertNil(client.requestedURL)
    }
}
