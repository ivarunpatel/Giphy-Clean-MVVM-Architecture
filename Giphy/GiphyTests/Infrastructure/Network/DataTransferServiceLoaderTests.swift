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
    case networkError(Error)
}

class DataTransferServiceLoader {
    let networkService: NetworkService
    
    init(networkService: NetworkService) {
        self.networkService = networkService
    }
    
    @discardableResult
    func request<T: Decodable, E: ResponseRequestable>(with endpoint: E, completion: @escaping (Result<T, DataTransferError>) -> Void) -> NetworkCancellable? where E.Response == T {
        networkService.request(endpoint: endpoint) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                let result: Result<T, DataTransferError> = decode(with: endpoint.responseDecoder, data: data)
                completion(result)
            case .failure(let error):
                completion(.failure(.networkError(error)))
            }
        }
    }
    
    private func decode<T: Decodable>(with decoder: ResponseDecoder, data: Data?) -> Result<T, DataTransferError> {
        guard let data = data else {
            return .failure(.noResponse)
        }
        do {
            let responseModel: T = try decoder.decode(data)
            return .success(responseModel)
        } catch {
            return .failure(.parsing(error))
        }
    }
}

final class DataTransferServiceLoaderTests: XCTestCase {
    
    func test_request_shouldReturnNoResponseErrorWhenResponseDataIsNil() {
        let (sut, loader) = makeSUT()
        let expectedError = DataTransferError.noResponse
        
        expect(sut, toCompleteWith: .failure(expectedError)) {
            loader.complete(with: nil)
        }
    }
    
    func test_request_shouldReturnParsingErrorOnInvalidJSONResponse() {
        let (sut, loader) = makeSUT()

        let expectedError = anyNSError()
        
        expect(sut, toCompleteWith: .failure(.parsing(expectedError))) {
            loader.complete(with: anyData())
        }
    }
    
    func test_request_shouldReturnNetworkErrorOnNetworkError() {
        let (sut, loader) = makeSUT()
        
        let expectedError = NetworkError.cancelled
        
        expect(sut, toCompleteWith: .failure(.networkError(expectedError))) {
            loader.complete(with: expectedError)
        }
    }
    
    func test_request_shouldSuccessfullyReturnParsedResponseOnValidJSONResponse() {
        let (sut, loader) = makeSUT()

        let expectedResponseModel = MockResponseModel(id: "1", url: anyURL())
        
        expect(sut, toCompleteWith: .success(expectedResponseModel)) {
            loader.complete(with: #"{"id": "1", "url": "http://any-url.com"}"#.data(using: .utf8))
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
        let id: String
        let url: URL
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
        
        func complete(with data: Data?, at index: Int = 0) {
            receivedMessages[index](.success(data))
        }
        
        func complete(with error: NetworkError, at index: Int = 0) {
            receivedMessages[index](.failure(.cancelled))
        }
    }
}

