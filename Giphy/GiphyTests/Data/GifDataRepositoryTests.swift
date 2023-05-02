//
//  GifDataRepositoryTests.swift
//  GiphyTests
//
//  Created by Varun on 02/05/23.
//

import XCTest
import Giphy

final public class GifDataRepositoryLoader {
    
    private let dataTransferService: DataTransferService
    
    public init(dataTransferService: DataTransferService) {
        self.dataTransferService = dataTransferService
    }
    
    func fetchGif(url: String, completion: @escaping (Result<Data, Error>) -> Void) -> Cancellable? {
        let endPoint = Endpoint<Data>(path: url, isFullPath: true, method: .get, responseDecoder: RawDataResponseDecoder())
        
        let task = RepositoryTask()
        task.networkTask = dataTransferService.request(with: endPoint, completion: { result in
            let mappedResult = result.mapError { $0 as Error }
            completion(mappedResult)
        })
        return task
    }
}

final class GifDataRepositoryTests: XCTestCase {
    
    func test_fetchGif_deliversDataOnSuccess() {
        let (sut, dataLoader) = makeSUT()
       
        expect(sut: sut, toCompleteWith: .success(anyData())) {
            dataLoader.complete(with: anyData())
        }
    }
    
    func test_fetchGif_deliversErrorOnFailure() {
        let (sut, dataLoader) = makeSUT()

        expect(sut: sut, toCompleteWith: .failure(DataTransferError.parsing(anyNSError()))) {
            dataLoader.complete(with: DataTransferError.parsing(anyNSError()))
        }
    }
    
    func test_fetchGif_doesNotReturnAfterRequestCancellation() {
        let (sut, dataLoader) = makeSUT()

        let expectation = expectation(description: "Waiting for completion")
       let task = sut.fetchGif(url: anyGifURLString()) { _ in
           expectation.fulfill()
        }
        
        task?.cancel()
        
        dataLoader.complete(with: anyData())
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(dataLoader.cancelledRequestURLPaths.count, 1)
    }
    
    // MARK: - Helper
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: GifDataRepositoryLoader, dataLoader: DataTransferServiceLoaderSpy<Data>) {
        let dataLoader = DataTransferServiceLoaderSpy<Data>()
        let sut = GifDataRepositoryLoader(dataTransferService: dataLoader)
        trackForMemoryLeaks(dataLoader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, dataLoader)
    }
    
    private func expect(sut: GifDataRepositoryLoader, toCompleteWith expectedResult: Result<Data, Error>, on action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        let expectation = expectation(description: "Waiting for completion")
        _ = sut.fetchGif(url: anyGifURLString()) { receivedResult in
            switch (receivedResult, expectedResult) {
            case (.success(let receivedGifData), .success(let expectedGifData)) :
                XCTAssertEqual(receivedGifData, expectedGifData, file: file, line: line)
            case (.failure(let receivedError as NSError), .failure(let expectedError as NSError)):
                XCTAssertEqual(receivedError.domain, expectedError.domain, file: file, line: line)
                XCTAssertEqual(receivedError.code, expectedError.code, file: file, line: line)
            default:
                XCTFail("Expected \(expectedResult) got, \(receivedResult) instead", file: file, line: line)
            }
            expectation.fulfill()
        }
        
        action()
        
        wait(for: [expectation], timeout: 1.0)
    }

    private func anyGifURLString() -> String {
        "https://media3.giphy.com/media/wvqrOGkwSf4O5eqPg3/giphy.gif?cid=a73e0a9dmg94h3r0hb22w56toxsu0gz3oyn2izeyt9wi6xvl&ep=v1_gifs_trending&rid=giphy.gif&ct=g"
    }
    
    private class DataTransferServiceLoaderSpy<R: Decodable>: DataTransferService {
        private var receivedMessages = [CompletionHandler<R>]()
        var cancelledRequestURLPaths = [String]()
        @discardableResult
        func request<T: Decodable, E: ResponseRequestable>(with endpoint: E, completion: @escaping CompletionHandler<T>) -> NetworkCancellable? where E.Response == T {
            receivedMessages.append(completion as! ((Result<R, DataTransferError>) -> Void))
            return NetworkCancellableSpy { [weak self] in
                self?.cancelledRequestURLPaths.append(endpoint.path)
            }
        }
        
        func complete(with model: Data, at index: Int = 0) {
            receivedMessages[index](.success(model as! R))
        }
        
        func complete(with error: DataTransferError, at index: Int = 0) {
            receivedMessages[index](.failure(error))
        }
    }

    private struct NetworkCancellableSpy: NetworkCancellable {
        let cancelCallback: () -> Void
        
        func cancel() {
            cancelCallback()
        }
        
    }
}
