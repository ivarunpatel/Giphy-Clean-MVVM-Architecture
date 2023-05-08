//
//  TrendingRepositoryTests.swift
//  GiphyTests
//
//  Created by Varun on 19/04/23.
//

import XCTest
import Giphy

final class TrendingRepositoryTests: XCTestCase {
    
    func test_fetchTrendingGiphyList_loadTrendingGiphyList() {
        let (sut, dataLoader) = makeSUT()
        
        let expectedModel = FeedResponseDTO(data: [FeedResponseDTO.FeedDataDTO(id: "1", title: "title", datetime: "any time", images: FeedResponseDTO.FeedDataDTO.FeedImagesDTO(original: FeedResponseDTO.FeedDataDTO.FeedImagesDTO.FeedImageMetadataDTO(height: "500", width: "500", url: anyURL()), small: FeedResponseDTO.FeedDataDTO.FeedImagesDTO.FeedImageMetadataDTO(height: "100", width: "100", url: anyURL())), user: FeedResponseDTO.FeedDataDTO.FeedUserDTO(username: "test_user", displayName: "test user"))], pagination: FeedResponseDTO.FeedPaginationDTO(totalCount: 10, count: 5, offset: 0))
        
        expect(sut: sut, toCompleteWith: .success(expectedModel.toDomain())) {
            dataLoader.complete(with: expectedModel)
        }
    }
    
    func test_fetchTrendingGiphyList_failsWithErrorOnError() {
        let (sut, dataLoader) = makeSUT()
        let expectedError = DataTransferError.noResponse
        expect(sut: sut, toCompleteWith: .failure(expectedError)) {
            dataLoader.complete(with: expectedError)
        }
    }
    
    // MARK: - Helpers

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: TrendingRepositoryLoader, dataLoader: DataTransferServiceLoaderSpy<FeedResponseDTO>) {
        let dataTransferServiceLoader = DataTransferServiceLoaderSpy<FeedResponseDTO>()
        let sut = TrendingRepositoryLoader(dataTransferService: dataTransferServiceLoader)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(dataTransferServiceLoader, file: file, line: line)
        return (sut, dataTransferServiceLoader)
    }
    
    private func expect(sut: TrendingRepositoryLoader, toCompleteWith expectedResult: TrendingRepository.Result, action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        let expectation = expectation(description: "Waiting for completion")
        _ = sut.fetchTrendingGiphyList(limit: 10, offset: 0) { receivedResult in
            switch (receivedResult, expectedResult) {
            case (.success(let receivedGiphyPage), .success(let expectedGiphyImage)):
                XCTAssertEqual(receivedGiphyPage, expectedGiphyImage, file: file, line: line)
            case (.failure(let receivedError as NSError), .failure(let expectedError as NSError)):
                XCTAssertEqual(receivedError.domain, expectedError.domain)
                XCTAssertEqual(receivedError.code, expectedError.code)
            default:
                XCTFail("Expected to receive \(expectedResult), got \(receivedResult) instead")
            }
            expectation.fulfill()
        }
        
        action()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    private class DataTransferServiceLoaderSpy<R: Decodable>: DataTransferService {
        private var receivedMessages = [CompletionHandler<R>]()
        
        @discardableResult
        func request<T: Decodable, E: ResponseRequestable>(with endpoint: E, completion: @escaping CompletionHandler<T>) -> NetworkCancellable? where E.Response == T {
            receivedMessages.append(completion as! ((Result<R, DataTransferError>) -> Void))
            return nil
        }
        
        func complete(with model: FeedResponseDTO, at index: Int = 0) {
            receivedMessages[index](.success(model as! R))
        }
        
        func complete(with error: DataTransferError, at index: Int = 0) {
            receivedMessages[index](.failure(error))
        }
    }
}
