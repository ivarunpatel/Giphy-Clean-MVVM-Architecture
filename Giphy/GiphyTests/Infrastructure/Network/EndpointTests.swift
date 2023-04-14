//
//  EndpointTests.swift
//  GiphyTests
//
//  Created by Varun on 14/04/23.
//

import XCTest
import Giphy

final class EndpointTests: XCTestCase {

    func test_urlRequest_prepareURLWithPath() throws {
        let path = "trending"
        let sut = makeSUT(with: path)
        
        let networkConfiguration = MockNetworkConfigurable()
        let urlRequest = try sut.urlRequest(with: networkConfiguration)
        
        XCTAssertEqual(urlRequest.url?.absoluteString, "http://any-url.com/\(path)")
    }
    
    func test_urlRequest_prepareURLRequestWithDefaultQueryParameters() throws {
        let sut = makeSUT()
        
        var networkConfiguration = MockNetworkConfigurable()
        networkConfiguration.setqueryParameters(queryParameters: ["rating": "g"])
        let urlRequest = try sut.urlRequest(with: networkConfiguration)
        
        XCTAssertEqual(urlRequest.url?.absoluteString, "http://any-url.com/trending?rating=g")
    }
    
    func test_urlRequest_prepareURLRequestWithHeaders() throws {
        let sut = makeSUT()
        
        var networkConfiguration = MockNetworkConfigurable()
        let headers = ["contentType": "application/json"]
        networkConfiguration.setHeaders(headers: ["contentType": "application/json"])
        let urlRequest = try sut.urlRequest(with: networkConfiguration)
        
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, headers)
    }
    
    func test_urlRequest_prepareURLRequestWithHTTPMethod() throws {
        let sut = makeSUT(method: .post)
        
        let networkConfiguration = MockNetworkConfigurable()
        let urlRequest = try sut.urlRequest(with: networkConfiguration)

        XCTAssertEqual(urlRequest.httpMethod, "POST")
    }
    
    // MARK: - Helpers

    private func makeSUT(with path: String = "trending", method: HTTPMethodType = .get, queryParameters: [String: String] = [:]) -> any ResponseRequestable {
        let endpoint = Endpoint<DummyResponseModel>(path: path, method: method, queryParameters: queryParameters, responseDecoder: MockResponseDecoder())
        
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
