//
//  EndpointTests.swift
//  GiphyTests
//
//  Created by Varun on 14/04/23.
//

import XCTest
import Giphy

final class EndpointTests: XCTestCase {

    func test_urlRequest_prepareValidURLWithPath() throws {
        let path = "somePath"
        let sut = makeSUT(with: path)
        
        var networkConfiguration = MockNetworkConfigurable()
        let urlRequest = try sut.urlRequest(with: networkConfiguration)
        
        XCTAssertEqual(urlRequest.url?.absoluteString, "http://any-url.com/\(path)")
    }
    
    func test_urlRequest_prepareValidURLRequestWithDefaultQueryParameters() throws {
        let sut = makeSUT()
        
        var networkConfiguration = MockNetworkConfigurable()
        networkConfiguration.setqueryParameters(queryParameters: ["rating": "g"])
        let urlRequest = try sut.urlRequest(with: networkConfiguration)
        
        XCTAssertEqual(urlRequest.url?.absoluteString, "http://any-url.com/somePath?rating=g")
    }
    
    func test_urlRequest_prepareValidURLRequestWithHeaders() throws {
        let sut = makeSUT()
        
        var networkConfiguration = MockNetworkConfigurable()
        let headers = ["contentType": "application/json"]
        networkConfiguration.setHeaders(headers: ["contentType": "application/json"])
        let urlRequest = try sut.urlRequest(with: networkConfiguration)
        
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, headers)
    }
    
    // MARK: - Helpers

    private func makeSUT(with path: String = "somePath") -> any ResponseRequestable {
        let endpoint = Endpoint<DummyResponseModel>(path: path, method: .get, queryParameters: [:], responseDecoder: MockResponseDecoder())
        
        return endpoint
    }
    
    
    private struct MockNetworkConfigurable: NetworkConfigurable {
        var baseURL: URL = URL(string: "http://any-url.com")!
        var headers: [String: String] = [:]
        var queryParameters: [String: String] = [:]
        
        mutating func setbaseURL(url: URL) {
            baseURL = url
        }
        
        mutating func setHeaders(headers: [String: String]) {
            self.headers = headers
        }
        
        mutating func setqueryParameters(queryParameters: [String: String]) {
            self.queryParameters = queryParameters
        }
    }
    
    private struct DummyResponseModel: Decodable { }
    
    private struct MockResponseDecoder: ResponseDecoder {
        func decode<T: Decodable>(_ data: Data) throws -> T {
            try JSONDecoder().decode(T.self, from: data)
        }
    }
    
    
}
