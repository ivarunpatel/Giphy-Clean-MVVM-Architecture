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
        
        expect(sut: sut, toCompleteWith: .connectivity, on: {
            let clientError = NSError(domain: "any error", code: -1)
            client.complete(with: clientError)
        })
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { (index, code) in
            expect(sut: sut, toCompleteWith: .invalidData) {
                client.complete(withStatusCode: code, index: index)
            }
        }
    }
    
    func test_load_deliversErrorOn200HTTPCodeWithInvalidJSON() {
        let (sut, client) = makeSUT()

        expect(sut: sut, toCompleteWith: .invalidData) {
            let invalidJSONData = Data("invalid json".utf8)
            client.complete(withStatusCode: 200, data: invalidJSONData)
        }
    }
    
    // MARK: - Helper
    
    private func makeSUT(url: URL = URL(string: "http://any-url.com")!) -> (RemoteGiphyLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteGiphyLoader(client: client, url: url)
        return (sut, client)
    }
    
    private func expect(sut: RemoteGiphyLoader, toCompleteWith expectedError: RemoteGiphyLoader.Error, on action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        
        var receivedErrors = [RemoteGiphyLoader.Error]()
        sut.load(completion: { receivedErrors.append($0) })
        
        action()
        
        XCTAssertEqual(receivedErrors, [expectedError], "Expected to received \(expectedError), got \(receivedErrors) instead", file: file, line: line)
    }
    
    final class HTTPClientSpy: HTTPClient {
        var messages = [(url: URL, completion: (Result<(Data, HTTPURLResponse), Error>) -> Void)]()
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }
        
        func get(from url: URL, completion: @escaping (Result<(Data, HTTPURLResponse), Error>) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, data: Data = Data(), index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index], statusCode: code, httpVersion: nil, headerFields: nil)
            messages[index].completion(.success((data, response!)))
        }
    }

}
