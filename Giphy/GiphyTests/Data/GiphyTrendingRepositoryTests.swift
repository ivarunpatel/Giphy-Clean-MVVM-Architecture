//
//  GiphyTrendingRepositoryTests.swift
//  GiphyTests
//
//  Created by Varun on 19/04/23.
//

import XCTest
import Giphy

final class GiphyTrendingRepositoryTests: XCTestCase {
    
    func test_fetchTrendingGiphyList_loadTrendingGiphyList() {
        let (sut, dataLoader) = makeSUT()
        
        let expectedModel = GiphyResponseDTO(data: [GiphyResponseDTO.GiphyDataDTO(id: "1", title: "title", datetime: "any time", images: GiphyResponseDTO.GiphyDataDTO.GiphyImagesDTO(original: GiphyResponseDTO.GiphyDataDTO.GiphyImagesDTO.GiphyImageMetadataDTO(height: "500", width: "500", url: anyURL()), small: GiphyResponseDTO.GiphyDataDTO.GiphyImagesDTO.GiphyImageMetadataDTO(height: "100", width: "100", url: anyURL())))], pagination: GiphyResponseDTO.PaginationDTO(totalCount: 10, count: 5, offset: 0))
        
        expect(sut: sut, toCompleteWith: .success(expectedModel.toDomain())) {
            dataLoader.complete(with: expectedModel)
        }
    }
    
    func test_fatchTrendingGiphyList_failsWithErrorOnError() {
        let (sut, dataLoader) = makeSUT()
        let expectedError = DataTransferError.noResponse
        expect(sut: sut, toCompleteWith: .failure(expectedError)) {
            dataLoader.complete(with: expectedError)
        }
    }
    
    // MARK: - Helpers

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: GiphyTrendingRepository, dataLoader: DataTransferServiceLoaderSpy<GiphyResponseDTO>) {
        let dataTransferServiceLoader = DataTransferServiceLoaderSpy<GiphyResponseDTO>()
        let sut = GiphyTrendingRepository(dataTransferService: dataTransferServiceLoader)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(dataTransferServiceLoader, file: file, line: line)
        return (sut, dataTransferServiceLoader)
    }
    
    private func expect(sut: GiphyTrendingRepository, toCompleteWith expectedResult: TrendingGiphyRepository.Result, action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        let expectation = expectation(description: "Waiting for completion")
       _ = sut.fetchTrendingGiphyList(limit: 10) { receivedResult in
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
        
        func complete(with model: GiphyResponseDTO, at index: Int = 0) {
            receivedMessages[index](.success(model as! R))
        }
        
        func complete(with error: DataTransferError, at index: Int = 0) {
            receivedMessages[index](.failure(error))
        }
    }
}
