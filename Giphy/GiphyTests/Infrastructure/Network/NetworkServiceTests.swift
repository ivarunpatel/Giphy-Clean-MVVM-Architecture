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
    
    struct UnexpectedNetworkError: Error { }
    
    func request(endpoint: Requestable, completionHandler: @escaping ((Error) -> Void)) {
        let request = try! endpoint.urlRequest(with: config)
        session.dataTask(with: request) { _, _, error in
            if let error = error {
                completionHandler(error)
            } else {
                completionHandler(UnexpectedNetworkError())
            }
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
        sut.request(endpoint: endpoint, completionHandler: { _ in })
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_request_failsOnRequestError() {
        let requestedError = anyNSError()
       let receivedError = requestFor(data: nil, response: nil, error: requestedError)

        XCTAssertEqual((receivedError as NSError?)?.domain, requestedError.domain)
        XCTAssertEqual((receivedError as NSError?)?.code, requestedError.code)
    }
    
    func test_request_failsInAllInvalidRepresentationCases() {
        XCTAssertNotNil(requestFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(requestFor(data: nil, response: nonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(requestFor(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(requestFor(data: anyData(), response: nil, error: anyNSError()))
        XCTAssertNotNil(requestFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(requestFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(requestFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(requestFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(requestFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))
    }
    
    // MARK: - Helpers
    
    private func makeSUT(config: NetworkConfigurable) -> NetworkService {
        let sut = NetworkService(config: config)
        return sut
    }
    
    private func requestFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> Error? {
        URLProtocolStub.stub(data: data, response: response, error: error)
        
        let sut = makeSUT(config: MockNetworkConfigurable())
        
        let path = "somePath"
        let endpoint = MockEndPoint(path: path, method: .post)
        let expectation = expectation(description: "Waiting for completion handler")
        var receivedError: Error?
        sut.request(endpoint: endpoint) { error in
            receivedError = error
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        return receivedError
    }
    
    private func nonHTTPURLResponse() -> URLResponse {
        URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: -1, textEncodingName: nil)
    }
    
    private func anyData() -> Data {
        Data("any data".utf8)
    }
    
    private func anyHTTPURLResponse() -> HTTPURLResponse {
        HTTPURLResponse(url: anyURL(), mimeType: nil, expectedContentLength: -1, textEncodingName: nil)
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
        private static var stub: Stub?
        
        struct Stub {
            var data: Data?
            var response: URLResponse?
            var error: Error?
        }
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            observeRequests = nil
            stub = nil
        }
        
        static func observeRequests(observer: @escaping ((URLRequest) -> Void)) {
            observeRequests = observer
        }
        
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
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
            
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {
            
        }
    }
    
}

