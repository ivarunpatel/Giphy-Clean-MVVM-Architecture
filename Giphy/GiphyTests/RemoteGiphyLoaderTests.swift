//
//  RemoteGiphyLoaderTests.swift
//  GiphyTests
//
//  Created by Varun on 11/04/23.
//

import XCTest
import Giphy

final class RemoteGiphyLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertNil(client.requestedURL)
    }
    
    func test_load_requestsDataFromURL() {
        let (sut, client) = makeSUT()
        
        sut.load()
        
        XCTAssertNotNil(client.requestedURL)
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "http://any-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load()
        sut.load()
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    // MARK: - Helper
    
    private func makeSUT(url: URL = URL(string: "http://any-url.com")!) -> (RemoteGiphyLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteGiphyLoader(client: client, url: url)
        return (sut, client)
    }
    
    final class HTTPClientSpy: HTTPClient {
        var requestedURL: URL?
        var requestedURLs = [URL]()
        
        func get(from url: URL) {
            requestedURL = url
            requestedURLs.append(url)
        }
    }

}
