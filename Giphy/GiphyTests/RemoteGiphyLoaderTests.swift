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
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        let url = URL(string: "http://any-url.com")!
        let (sut, client) = makeSUT()
        
        sut.load()
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "http://any-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load()
        sut.load()
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        
        var capturedError: RemoteGiphyLoader.Error?
        sut.load(completion: { capturedError = $0 })
        
        let clientError = NSError(domain: "any error", code: -1)
        client.complete(with: clientError)
        
        XCTAssertEqual(capturedError, .connectivity)
    }
    
    // MARK: - Helper
    
    private func makeSUT(url: URL = URL(string: "http://any-url.com")!) -> (RemoteGiphyLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteGiphyLoader(client: client, url: url)
        return (sut, client)
    }
    
    final class HTTPClientSpy: HTTPClient {
        var requestedURLs = [URL]()
        var completions = [(Error) -> Void]()
        
        func get(from url: URL, completion: @escaping (Error) -> Void) {
            requestedURLs.append(url)
            completions.append(completion)
        }
        
        func complete(with error: Error, at index: Int = 0) {
            completions[index](error)
        }
    }

}
