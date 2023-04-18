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
    case parsing(Error)
}

class DataTransferServiceLoader {
    let networkService: NetworkService
    
    init(networkService: NetworkService) {
        self.networkService = networkService
    }
    
    @discardableResult
    func request<T: Decodable, E: ResponseRequestable>(with endpoint: E, completion: @escaping (Result<T, DataTransferError>) -> Void) -> NetworkCancellable? where E.Response == T {
        networkService.request(endpoint: endpoint) { result in
            switch result {
            case .success(let data):
                if let data = data {
                    do {
                        let responseModel: T = try endpoint.responseDecoder.decode(data)
                        completion(.success(responseModel))
                    } catch {
                        completion(.failure(.parsing(error)))
                    }
                } else {
                    completion(.failure(.noResponse))
                }
            default: break
            }
        }
    }
}

final class DataTransferServiceLoaderTests: XCTestCase {
    
//    func test_request_shouldReturnNoResponseErrorWhenResponseDataIsNil() {
//        let (sut, loader) = makeSUT()
//        let expectedError = DataTransferError.noResponse
//        let endPoint = Endpoint<MockResponseModel>(path: "somePath", method: .get, responseDecoder: JSONResponseDecoder())
//        let expectation = expectation(description: "Waiting for completion")
//        var receivedError: DataTransferError?
//        sut.request(with: endPoint) { error in
//            receivedError = error
//            expectation.fulfill()
//        }
//        
//        loader.complete()
//                
//        wait(for: [expectation], timeout: 1.0)
//
//        XCTAssertEqual((receivedError as NSError?)?.domain, (expectedError as NSError?)?.domain)
//        XCTAssertEqual((receivedError as NSError?)?.code, (expectedError as NSError?)?.code)
//    }
    
    func test_request_shouldReturnParsingErrorOnJSONDataParsingError() {
        let (sut, loader) = makeSUT()

        let expectedError = anyNSError()
        
        expect(sut, toCompleteWith: .failure(.parsing(expectedError))) {
            loader.complete(with: anyData())
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: DataTransferServiceLoader, loader: NetworkServiceLoaderStub) {
        let networkServiceLoaderStub = NetworkServiceLoaderStub()
        let sut = DataTransferServiceLoader(networkService: networkServiceLoaderStub)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(networkServiceLoaderStub, file: file, line: line)
        return (sut, networkServiceLoaderStub)
    }
    
    private func expect(_ sut: DataTransferServiceLoader, toCompleteWith expectedResult: Result<MockResponseModel, DataTransferError>, action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        let endPoint = Endpoint<MockResponseModel>(path: "somePath", method: .get, responseDecoder: JSONResponseDecoder())
        
        let expectation = expectation(description: "Waiting for completion")
        sut.request(with: endPoint) { receivedResult in
            switch (receivedResult, expectedResult) {
            case (.success(let receivedModel), .success(let expectedModel)):
                XCTAssertEqual(receivedModel, expectedModel, file: file, line: line)
            case (.failure(let receivedError), .failure(let expectedError)):
                XCTAssertEqual((receivedError as NSError?)?.domain, (expectedError as NSError?)?.domain, file: file, line: line)
                XCTAssertEqual((receivedError as NSError?)?.code, (expectedError as NSError?)?.code, file: file, line: line)
            default:
                XCTFail("Expected \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            expectation.fulfill()
        }
        
        action()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    private struct MockResponseModel: Decodable, Equatable {
        
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

