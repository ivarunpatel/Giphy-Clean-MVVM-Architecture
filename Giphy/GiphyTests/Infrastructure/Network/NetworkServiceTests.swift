//
//  NetworkServiceTests.swift
//  GiphyTests
//
//  Created by Varun on 17/04/23.
//

import XCTest
import Giphy

class NetworkService {
    let config: NetworkConfigurable
    let session: URLSession
    
    init(config: NetworkConfigurable, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }
    
    func request(endpoint: Requestable) {
        let request = try! endpoint.urlRequest(with: config)
        session.dataTask(with: request) { _, _, _ in
            
        }.resume()
    }
}

final class NetworkServiceTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
        super.tearDown()
        
        URLProtocolStub.stopInterceptingRequests()
    }
    
    func test_request_performRequestWithURL() {
        let path = "somePath"
        let endpoint = MockEndPoint(path: path, method: .post)
        let expectedURL = anyURL().appending(path: path)
        
        let expectation = expectation(description: "Waiting for request")
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, expectedURL)
            XCTAssertEqual(request.httpMethod, endpoint.method.rawValue)
            expectation.fulfill()
        }
        
        let sut = makeSUT(config: MockNetworkConfigurable())
        sut.request(endpoint: endpoint)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(config: MockNetworkConfigurable) -> NetworkService {
        let sut = NetworkService(config: config)
        return sut
    }
    
    private struct MockNetworkConfigurable: NetworkConfigurable {
        var baseURL: URL = anyURL()
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
    
    private class MockEndPoint: Requestable {
        var path: String
        var method: Giphy.HTTPMethodType
        var queryParameters: [String : String] = [:]
        
        init(path: String, method: HTTPMethodType) {
            self.path = path
            self.method = method
        }
    }
    
    private class URLProtocolStub: URLProtocol {
        
       private static var observeRequests: ((URLRequest) -> Void)?
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
        }
        
        static func observeRequests(observer: @escaping ((URLRequest) -> Void)) {
            observeRequests = observer
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            if let observer = URLProtocolStub.observeRequests {
                client?.urlProtocolDidFinishLoading(self)
                return observer(request)
            }
        }
        
        override func stopLoading() {
            
        }
    }

}

