//
//  RemoteGiphyLoaderTests.swift
//  GiphyTests
//
//  Created by Varun on 11/04/23.
//

import XCTest

class RemoteGiphyLoader {
    let client: HTTPClient
    
    init(client: HTTPClient) {
        self.client = client
    }
    
    func load() {
        client.requestedURL = URL(string: "http://any-url.com")!
    }
}

final class HTTPClient {
    
    init() {
        
    }
    
    var requestedURL: URL?
}

final class RemoteGiphyLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertNil(client.requestedURL)
    }
    
    func test_load_requestDataFromURL() {
        let (sut, client) = makeSUT()
        
        sut.load()
        
        XCTAssertNotNil(client.requestedURL)
    }
    
    // MARK: - Helper
    
    private func makeSUT() -> (RemoteGiphyLoader, HTTPClient) {
        let client = HTTPClient()
        let sut = RemoteGiphyLoader(client: client)
        return (sut, client)
    }

}
