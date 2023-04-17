//
//  NetworkServiceTests.swift
//  GiphyTests
//
//  Created by Varun on 17/04/23.
//

import XCTest
import Giphy

enum NetworkError: Error {
    case error(statusCode: Int, data: Data?)
    case notConnected
    case cancelled
    case generic(Error)
    case urlGeneration
    case unknown
}

class NetworkService {
    let config: NetworkConfigurable
    let session: URLSession
    
    init(config: NetworkConfigurable, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }
        
    func request(endpoint: Requestable, completionHandler: @escaping ((Result<Data?, NetworkError>) -> Void)) {
        do {
            let urlRequest = try endpoint.urlRequest(with: config)
            request(request: urlRequest, completionHandler: completionHandler)
        } catch {
            completionHandler(.failure(NetworkError.urlGeneration))
        }
    }
    
    private func request(request: URLRequest, completionHandler: @escaping ((Result<Data?, NetworkError>) -> Void)) {
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                let networkError = self.handle(error: error, with: response, data: data)
                completionHandler(.failure(networkError))
            } else if let data = data, response is HTTPURLResponse {
                completionHandler(.success(data))
            } else {
                completionHandler(.failure(NetworkError.unknown))
            }
        }.resume()
    }
    
    private func handle(error: Error, with response: URLResponse?, data: Data?) -> NetworkError {
        if let response = response as? HTTPURLResponse {
            return .error(statusCode: response.statusCode, data: data)
        } else {
            return self.resolve(error: error)
        }
    }
    
    private func resolve(error: Error) -> NetworkError {
        let code = URLError.Code(rawValue: (error as NSError).code)
        switch code {
        case .notConnectedToInternet:
            return .notConnected
        case .cancelled:
            return .cancelled
        default:
            return .generic(error)
        }
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
        let requestedError = NetworkError.generic(anyNSError())
        let receivedError = receiveErrorFor(data: nil, response: nil, error: requestedError)
        
        XCTAssertEqual((receivedError as NSError?)?.domain, (requestedError as NSError?)?.domain)
        XCTAssertEqual((receivedError as NSError?)?.code, (requestedError as NSError?)?.code)
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
        let sut = NetworkService(config: config)
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
    
    private func requestFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> Result<Data?, NetworkError> {
        URLProtocolStub.stub(data: data, response: response, error: error)
        
        let sut = makeSUT(config: MockNetworkConfigurable())
        
        let path = "somePath"
        let endpoint = MockEndPoint(path: path, method: .post)
        let expectation = expectation(description: "Waiting for completion handler")
        var receivedResult: Result<Data?, NetworkError>!
        sut.request(endpoint: endpoint) { result in
            receivedResult = result
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        return receivedResult
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

