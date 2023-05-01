//
//  FeedViewModelTests.swift
//  GiphyTests
//
//  Created by Varun on 27/04/23.
//

import XCTest
import GiphyiOSApp
import Giphy

final class FeedViewModelTests: XCTestCase {
    
    func test_init_doesNotLoadItems() {
        let (_, useCase) = makeSUT()
        
        XCTAssertTrue(useCase.receivedMessages.isEmpty)
    }
    
    func test_viewDidLoad_loadItemsOnSuccessfulUseCaseExecution() {
        let (sut, useCase) = makeSUT()
        
        XCTAssertEqual(sut.state.value, .none)
        
        sut.viewDidLoad()
        
        XCTAssertEqual(sut.state.value, .loading)
        
        let (feed, feedListItemViewModel) = makeItem()
        let feedPage = makeFeedPage(totalCount: 5, count: 2, offset: 0, feed: [feed])
        useCase.complete(with: feedPage)
        
        XCTAssertEqual(sut.items.value, [feedListItemViewModel])
        XCTAssertEqual(sut.state.value, .none)
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
    
    func test_didLoadNextPage_loadItemsFromNextPage() {
        let (sut, useCase) = makeSUT()

        XCTAssertEqual(sut.state.value, .none)

        sut.viewDidLoad()
        
        XCTAssertEqual(sut.state.value, .loading)

        let (firstPageItems, firstPageItemsViewModels) = makePageWithTwoItems(offset: 0)
        useCase.complete(with: firstPageItems)

        sut.didLoadNextPage()
        
        XCTAssertEqual(sut.state.value, .nextPage)

        let (secondPageItems, secondPageItemsViewModels) = makePageWithTwoItems(offset: 2)
        useCase.complete(with: secondPageItems)

        let accumulatedItemsViewModels = firstPageItemsViewModels + secondPageItemsViewModels
        
        XCTAssertEqual(sut.items.value, accumulatedItemsViewModels)
        XCTAssertEqual(sut.state.value, .none)
    }
    
    func test_didRefreshFeed_resetPageSetThenloadFirstPage() {
        let (sut, useCase) = makeSUT()
        
        XCTAssertEqual(sut.state.value, .none)

        sut.viewDidLoad()
        
        XCTAssertEqual(sut.state.value, .loading)

        let (firstPageItems, firstPageItemsViewModels) = makePageWithTwoItems(offset: 0)
        useCase.complete(with: firstPageItems)
        
        sut.didLoadNextPage()
        
        XCTAssertEqual(sut.state.value, .nextPage)

        let (secondPageItems, _) = makePageWithTwoItems(offset: 2)
        useCase.complete(with: secondPageItems)
        
        sut.didRefreshFeed()
        
        XCTAssertEqual(sut.state.value, .loading)

        useCase.complete(with: firstPageItems)
        
        XCTAssertEqual(sut.items.value, firstPageItemsViewModels)
        XCTAssertEqual(sut.state.value, .none)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: FeedViewModel, useCase: TrendingUseCaseSpy) {
        let useCase = TrendingUseCaseSpy()
        let sut = FeedViewModel(useCase: useCase)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(useCase, file: file, line: line)
        return (sut, useCase)
    }
    
    private func makeFeedPage(totalCount: Int, count: Int, offset: Int, feed: [Feed]) -> FeedPage {
        FeedPage(totalCount: totalCount, count: count, offset: offset, giphy: feed)
    }
    
    private func makeItem() -> (Feed, FeedListItemViewModel) {
        let feed = Feed(id: anyRandomId(), title: "title", datetime: "2021-05-21 19:17:34", images: FeedImages(original: FeedImageMetadata(height: "500", width: "500", url: anyURL()), small: FeedImageMetadata(height: "100", width: "100", url: anyURL())), user: FeedUser(username: "test", displayName: "test_name"))
        let feedListItemViewModel = FeedListItemViewModel(feed: feed)
        return (feed, feedListItemViewModel)
    }
    
    private func makePageWithTwoItems(offset: Int) -> (feedPage: FeedPage, feedListItemViewModels: [FeedListItemViewModel]) {
        let (feed1, feedListItemViewModel1) = makeItem()
        let (feed2, feedListItemViewModel2) = makeItem()
        let feedPage = makeFeedPage(totalCount: 4, count: 2, offset: offset, feed: [feed1, feed2])
        return (feedPage, [feedListItemViewModel1, feedListItemViewModel2])
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
