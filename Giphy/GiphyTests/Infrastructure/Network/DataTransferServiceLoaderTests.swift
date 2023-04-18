//
//  DataTransferServiceLoaderTests.swift
//  GiphyTests
//
//  Created by Varun on 18/04/23.
//

import XCTest
import Giphy

enum DataTransferError: Error {
    case noResponse
}

class DataTransferServiceLoader {
    let networkService: NetworkService
    
    init(networkService: NetworkService) {
        self.networkService = networkService
    }
    
    @discardableResult
    func request<E: ResponseRequestable>(with endpoint: E, completion: @escaping (DataTransferError) -> Void) -> NetworkCancellable? {
        networkService.request(endpoint: endpoint) { result in
            switch result {
            case .success(let data):
                if let data = data {
                    completion(.noResponse)
                }
            default: break
            }
        }
    }
}

final class DataTransferServiceLoaderTests: XCTestCase {
    
    func test_request_shouldReturnNoResponseErrorWhenCompletesWithoutData() {
        let (sut, loader) = makeSUT()
        let expectedError = DataTransferError.noResponse
        let endPoint = MockEndPoint<MockResponseModel>(path: "somePath", method: .get, responseDecoder: JSONResponseDecoder())
        let expectation = expectation(description: "Waiting for completion")
        var receivedError: DataTransferError?
        sut.request(with: endPoint) { error in
            receivedError = error
            expectation.fulfill()
        }
        
        loader.complete()
                
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual((receivedError as NSError?)?.domain, (expectedError as NSError?)?.domain)
        XCTAssertEqual((receivedError as NSError?)?.code, (expectedError as NSError?)?.code)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: DataTransferServiceLoader, loader: NetworkServiceLoaderStub) {
        let networkServiceLoaderStub = NetworkServiceLoaderStub()
        let sut = DataTransferServiceLoader(networkService: networkServiceLoaderStub)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(networkServiceLoaderStub, file: file, line: line)
        return (sut, networkServiceLoaderStub)
    }
    
    private struct MockResponseModel: Decodable {
        
    }
    
    private class MockEndPoint<R>: ResponseRequestable {
        typealias Response = R
                
        var path: String
        var method: HTTPMethodType
        var queryParameters: [String : String] = [:]
        
        var responseDecoder: ResponseDecoder

        init(path: String, method: HTTPMethodType, responseDecoder: ResponseDecoder) {
            self.path = path
            self.method = method
            self.responseDecoder = responseDecoder
        }
    }
    
    private class JSONResponseDecoder: ResponseDecoder {
        func decode<T: Decodable>(_ data: Data) throws -> T {
           try JSONDecoder().decode(T.self, from: data)
        }
    }
    
    private final class NetworkServiceLoaderStub: NetworkService {
        var receivedMessages = [((NetworkService.Result) -> Void)]()
        
        func request(endpoint: Requestable, completion: @escaping ((NetworkService.Result) -> Void)) -> NetworkCancellable? {
            receivedMessages.append(completion)
            return nil
        }
        
        func complete(with data: Data = Data(), at index: Int = 0) {
            receivedMessages[index](.success(data))
        }
    }
}

