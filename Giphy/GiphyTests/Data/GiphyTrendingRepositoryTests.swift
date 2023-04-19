//
//  GiphyTrendingRepositoryTests.swift
//  GiphyTests
//
//  Created by Varun on 19/04/23.
//

import XCTest
import Giphy

struct GiphyResponseDTO: Decodable {
    let data: [GiphyDataDTO]
    let pagination: PaginationDTO
}

extension GiphyResponseDTO {
    struct GiphyDataDTO: Decodable {
        let id: String
        let title: String
        let datetime: String
        let images: GiphyImagesDTO
        
        enum CodingKeys: String, CodingKey {
            case id
            case title
            case datetime = "import_datetime"
            case images
        }
        
        struct GiphyImagesDTO: Decodable {
            let original: GiphyImageMetadataDTO
            let small: GiphyImageMetadataDTO
            
            enum CodingKeys: String, CodingKey {
                case original
                case small = "fixed_width_small"
            }
            
            struct GiphyImageMetadataDTO: Decodable {
                let height: String
                let width: String
                let url: URL
            }
        }
    }
    
    struct PaginationDTO: Decodable {
        let totalCount: Int
        let count: Int
        let offset: Int
        
        enum CodingKeys: String, CodingKey {
            case totalCount = "total_count"
            case count
            case offset
        }
    }
}

// MARK: - Mappings to Domain
extension GiphyResponseDTO {
    func toDomain() -> GiphyPage {
        GiphyPage(totalCount: pagination.totalCount, count: pagination.count, offset: pagination.offset, giphy: data.map { $0.toDomain() })
    }
}

extension GiphyResponseDTO.GiphyDataDTO {
    func toDomain() -> Giphy {
        Giphy(id: id, title: title, datetime: datetime, images: images.toDomain())
    }
}

extension GiphyResponseDTO.GiphyDataDTO.GiphyImagesDTO {
    func toDomain() -> GiphyImages {
        GiphyImages(original: original.toDomain(), small: small.toDomain())
    }
}

extension GiphyResponseDTO.GiphyDataDTO.GiphyImagesDTO.GiphyImageMetadataDTO {
    func toDomain() -> GiphyImageMetadata {
        GiphyImageMetadata(height: height, width: width, url: url)
    }
}
    
struct Giphy: Equatable {
    let id: String
    let title: String
    let datetime: String
    let images: GiphyImages
}

struct GiphyImages: Equatable {
    let original: GiphyImageMetadata
    let small: GiphyImageMetadata
}

struct GiphyImageMetadata: Equatable {
    let height: String
    let width: String
    let url: URL
}

struct GiphyPage: Equatable {
    let totalCount: Int
    let count: Int
    let offset: Int
    let giphy: [Giphy]
}

final class GiphyTrendingRepository {
    
    let dataTransferService: DataTransferService
    
    init(dataTransferService: DataTransferService) {
        self.dataTransferService = dataTransferService
    }
    
    func fetchTrendingGiphyList(limit: Int, completion: @escaping (Result<GiphyPage, Error>) -> Void) {
        let endpoint = Endpoint<GiphyResponseDTO>(path: "/v1/gifs/trending", method: .get)
        dataTransferService.request(with: endpoint) { result in
            switch result {
            case .success(let responseModel):
                completion(.success(responseModel.toDomain()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

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

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: GiphyTrendingRepository, dataLoader: DataTransferServiceLoaderStub<GiphyResponseDTO>) {
        let dataTransferServiceLoader = DataTransferServiceLoaderStub<GiphyResponseDTO>()
        let sut = GiphyTrendingRepository(dataTransferService: dataTransferServiceLoader)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(dataTransferServiceLoader, file: file, line: line)
        return (sut, dataTransferServiceLoader)
    }
    
    private func expect(sut: GiphyTrendingRepository, toCompleteWith expectedResult: Result<GiphyPage, Error>, action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        let expectation = expectation(description: "Waiting for completion")
        sut.fetchTrendingGiphyList(limit: 10) { receivedResult in
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
    
    private class DataTransferServiceLoaderStub<R: Decodable>: DataTransferService {
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
