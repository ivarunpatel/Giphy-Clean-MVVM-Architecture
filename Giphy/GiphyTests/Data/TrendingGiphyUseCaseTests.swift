//
//  TrendingGiphyUseCaseTests.swift
//  GiphyTests
//
//  Created by Varun on 19/04/23.
//

import XCTest
import Giphy

final class TrendingGiphyUseCaseTests: XCTestCase {
    
    func test_execute_deliversTrendingGiphy() {
        let (sut, repository) = makeSUT()
        
        let expectedResult = GiphyPage(totalCount: 20, count: 10, offset: 0, giphy: [Giphy(id: "1", title: "title", datetime: "any time", images: GiphyImages(original: GiphyImageMetadata(height: "500", width: "500", url: anyURL()), small: GiphyImageMetadata(height: "100", width: "100", url: anyURL())))])
        
        let requestValue = TrendingGiphyUseCaseRequestValue(limit: 10)
        expect(sut: sut, requestValue: requestValue, toCompleteWith: .success(expectedResult)) {
            repository.complete(with: expectedResult)
        }
    }
    
    func test_expecute_deliversErrorOnError() {
        let (sut, repository) = makeSUT()
        let expectedError = anyNSError()
        
        let requestValue = TrendingGiphyUseCaseRequestValue(limit: 10)
        expect(sut: sut, requestValue: requestValue, toCompleteWith: .failure(expectedError)) {
            repository.complete(with: expectedError)
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (useCase: any TrendingGiphyUseCase, repository: TrendingGiphyRepositorySpy) {
        let repository = TrendingGiphyRepositorySpy()
        let useCase = DefaultTrendingGiphyUseCase(trendingGiphyRepository: repository)
        trackForMemoryLeaks(repository, file: file, line: line)
        trackForMemoryLeaks(useCase, file: file, line: line)
        return (useCase, repository)
    }
    
    private func expect(sut: any TrendingGiphyUseCase, requestValue: TrendingGiphyUseCaseRequestValue, toCompleteWith expectedResult: Result<GiphyPage, Error>, action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        
        let expectation = expectation(description: "Waiting for completion")
        _ = sut.execute(requestValue: requestValue) { receivedResult in
            switch (receivedResult, expectedResult) {
            case (.success(let receivedGiphyPage), .success(let expectedGiphyImage)):
                XCTAssertEqual(receivedGiphyPage, expectedGiphyImage, file: file, line: line)
            case (.failure(let receivedError as NSError), .failure(let expectedError as NSError)):
                XCTAssertEqual(receivedError.domain, expectedError.domain, file: file, line: line)
                XCTAssertEqual(receivedError.code, expectedError.code, file: file, line: line)
            default:
                XCTFail("Expected to receive \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            expectation.fulfill()
        }
        
        action()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    final class TrendingGiphyRepositorySpy: TrendingGiphyRepository {
        private var receivedMessages = [(TrendingGiphyRepository.Result) -> Void]()
        
        func fetchTrendingGiphyList(limit: Int, completion: @escaping (TrendingGiphyRepository.Result) -> Void) -> Cancellable? {
            receivedMessages.append(completion)
            return nil
        }
        
        func complete(with giphyPage: GiphyPage, at index: Int = 0) {
            receivedMessages[index](.success(giphyPage))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            receivedMessages[index](.failure(error))
        }
    }

}
