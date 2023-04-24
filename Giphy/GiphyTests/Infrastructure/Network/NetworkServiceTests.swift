//
//  NetworkServiceTests.swift
//  GiphyTests
//
//  Created by Varun on 17/04/23.
//

import XCTest
import Giphy

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
        _ = sut.request(endpoint: endpoint, completion: { _ in })
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_request_failsOnRequestError() {
        let requestedError = NetworkError.generic(anyNSError())
        let receivedError = receiveErrorFor(data: nil, response: nil, error: requestedError)
        
        XCTAssertEqual((receivedError as NSError?)?.domain, (requestedError as NSError?)?.domain)
        XCTAssertEqual((receivedError as NSError?)?.code, (requestedError as NSError?)?.code)
    }
    
    func test_reques_failsWithNotConnectedErrorWhenNotConnectedToInternet() {
        let requestedError = notConnectedToInternetError()
        let receivedError = receiveErrorFor(data: nil, response: nil, error: requestedError)
        
        XCTAssertEqual((receivedError as NSError?)?.domain, (NetworkError.notConnected as NSError?)?.domain)
        XCTAssertEqual((receivedError as NSError?)?.code, (NetworkError.notConnected as NSError?)?.code)
    }
    
    func test_request_failsInAllInvalidRepresentationCases() {
        XCTAssertNotNil(receiveErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(receiveErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(receiveErrorFor(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(receiveErrorFor(data: anyData(), response: nil, error: anyNSError()))
        XCTAssertNotNil(receiveErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(receiveErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(receiveErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(receiveErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(receiveErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))
    }
    
    func test_request_succeedOnHTTPURLResponseWithData() {
        let requestedData = anyData()
        let requestedResponse = anyHTTPURLResponse()
        
        let receivedValue = receiveValueFor(data: requestedData, response: requestedResponse, error: nil)
        
        XCTAssertEqual(receivedValue, requestedData)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(config: NetworkConfigurable) -> NetworkService {
        let sut = NetworkServiceLoader(config: config)
        return sut
    }
    
    private func receiveErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> NetworkError? {
        
        let receivedResult = requestFor(data: data, response: response, error: error)
        
        switch receivedResult {
        case .failure(let error):
            return error
        default:
            return nil
        }
    }
    
    private func receiveValueFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> Data? {
        
        let receivedResult = requestFor(data: data, response: response, error: error)
        
        switch receivedResult {
        case .success(let data):
            return data
        default:
            return nil
        }
    }
    
    private func requestFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> NetworkService.Result {
        URLProtocolStub.stub(data: data, response: response, error: error)
        
        let sut = makeSUT(config: MockNetworkConfigurable())
        
        let path = "somePath"
        let endpoint = MockEndPoint(path: path, method: .post)
        let expectation = expectation(description: "Waiting for completion handler")
        var receivedResult: NetworkService.Result!
        _ = sut.request(endpoint: endpoint) { result in
            receivedResult = result
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        return receivedResult
    }
    
    private func notConnectedToInternetError() -> NSError {
        NSError(domain: "Not connected", code: NSURLErrorNotConnectedToInternet)
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
    
    private class MockEndPoint: Requestable {
        var path: String
        var method: HTTPMethodType
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
            
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
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

