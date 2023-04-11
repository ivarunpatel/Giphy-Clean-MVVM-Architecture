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
        
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "http://any-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        
        var capturedErrors = [RemoteGiphyLoader.Error]()
        sut.load(completion: { capturedErrors.append($0) })
        
        let clientError = NSError(domain: "any error", code: -1)
        client.complete(with: clientError)
        
        XCTAssertEqual(capturedErrors, [.connectivity])
    }
    
    // MARK: - Helper
    
    private func makeSUT(url: URL = URL(string: "http://any-url.com")!) -> (RemoteGiphyLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteGiphyLoader(client: client, url: url)
        return (sut, client)
    }
    
    final class HTTPClientSpy: HTTPClient {
        var messages = [(url: URL, completion: (Error) -> Void)]()
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }
        
        func get(from url: URL, completion: @escaping (Error) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(error)
        }
    }

}
