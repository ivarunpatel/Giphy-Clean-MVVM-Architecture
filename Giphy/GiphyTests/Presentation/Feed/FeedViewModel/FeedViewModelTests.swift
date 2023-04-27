//
//  FeedViewModelTests.swift
//  GiphyTests
//
//  Created by Varun on 27/04/23.
//

import XCTest
import Giphy

final class FeedViewModel {
    
    let useCase: TrendingUseCase
    
    init(useCase: TrendingUseCase) {
        self.useCase = useCase
    }
    
    var items: Observable<FeedPage?> = Observable(.none)
    var error: Observable<String> = Observable("")
    
    func viewDidLoad() {
        _ = useCase.execute(requestValue: .init(limit: 10)) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let feedPage):
                items.value = feedPage
            case .failure(let error):
                self.handleError(error: error)
            }
        }
    }
    
    private func handleError(error: Error) {
        self.error.value = error.isInternetConnectionError ? "No internet connection" : "Failed to load feed"
    }
}

final class FeedViewModelTests: XCTestCase {
    
    func test_init_doesNotLoadItems() {
        let (_, useCase) = makeSUT()
        
        XCTAssertTrue(useCase.receivedMessages.isEmpty)
    }
    
    func test_viewDidLoad_loadItemsOnSuccessfulUseCaseExecution() {
        let (sut, useCase) = makeSUT()
        
        sut.viewDidLoad()
        
        let expectedValue = makeFeedItem()
        useCase.complete(with: expectedValue)
        
        XCTAssertEqual(sut.items.value, expectedValue)
    }
    
    func test_viewDidLoad_returnNoInternetConnectionErrorMessageWhenUseCaseFailWithNetworkError() {
        let (sut, useCase) = makeSUT()
        
        sut.viewDidLoad()
        
        let intetnetConnectionError = DataTransferError.networkError(NetworkError.notConnected)
        useCase.complete(with: intetnetConnectionError)
        
        XCTAssertEqual(sut.error.value, "No internet connection")
    }
    
    func test_viewDidLoad_returnFailedToLoadFeedErrorMessageWhenUseCaseFailWithAnyErrorOtherThanNetworkError() {
        let (sut, useCase) = makeSUT()
        
        sut.viewDidLoad()
        
        let error = anyNSError()
        useCase.complete(with: error)
        
        XCTAssertEqual(sut.error.value, "Failed to load feed")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: FeedViewModel, useCase: TrendingUseCaseSpy) {
        let useCase = TrendingUseCaseSpy()
        let sut = FeedViewModel(useCase: useCase)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(useCase, file: file, line: line)
        return (sut, useCase)
    }
    
    private final class TrendingUseCaseSpy: TrendingUseCase {
        public private(set) var receivedMessages = [(Result<FeedPage, Error>) -> Void]()
        
        func execute(requestValue: TrendingGiphyUseCaseRequestValue, completion: @escaping (Result<FeedPage, Error>) -> Void) -> Cancellable? {
            receivedMessages.append(completion)
            return nil
        }
        
        func complete(with feed: FeedPage, at index: Int = 0) {
            receivedMessages[index](.success(feed))
        }
        
        func complete(with feed: Error, at index: Int = 0) {
            receivedMessages[index](.failure(feed))
        }
    }
    
}
