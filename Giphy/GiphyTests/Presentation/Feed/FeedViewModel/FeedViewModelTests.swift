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
    
    private let parPageItem = 10
    private var totalCount = 0
    private var count = 0
    private var offSet = 0
    private var hasMorePage: Bool {
        (count + offSet) < totalCount
    }
    private var pages: [FeedPage] = []
    
    func viewDidLoad() {
        loadFeed()
    }
    
    func didLoadNextPage() {
        loadFeed()
    }
    
    private func loadFeed() {
        _ = useCase.execute(requestValue: .init(limit: parPageItem)) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let feedPage):
                totalCount = feedPage.totalCount
                count = feedPage.count
                offSet = feedPage.offset
                
                appendPage(feedPage: feedPage)
            case .failure(let error):
                handleError(error: error)
            }
        }
    }
    
    private func appendPage(feedPage: FeedPage) {
        pages = pages.filter { $0.offset != feedPage.offset } + [feedPage]
        var lastPage = pages.last
        let feedItems = pages.flatMap { $0.giphy }
        lastPage = FeedPage(totalCount: lastPage?.totalCount ?? 0, count: lastPage?.count ?? 0, offset: lastPage?.offset ?? 0, giphy: feedItems)
        items.value = lastPage
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
    
    func test_didLoadNextPage_loadItemsFromNextPage() {
        let (sut, useCase) = makeSUT()

        sut.viewDidLoad()

        let feed1 = makeItem(id: "123")
        let feed2 = makeItem(id: "456")
        let firstPageItems = makeItemWithPage(totalCount: 4, count: 2, offset: 0, feed: [feed1, feed2])
        useCase.complete(with: firstPageItems)

        XCTAssertEqual(sut.items.value, firstPageItems)

        sut.didLoadNextPage()

        let feed3 = makeItem(id: "789")
        let feed4 = makeItem(id: "101112")
        let secondPageItems = makeItemWithPage(totalCount: 4, count: 2, offset: 2, feed: [feed3, feed4])
        useCase.complete(with: secondPageItems)

        let accumulatedItems = FeedPage(totalCount: secondPageItems.totalCount, count: secondPageItems.count, offset: secondPageItems.offset, giphy: [feed1, feed2, feed3, feed4])
        XCTAssertEqual(sut.items.value, accumulatedItems)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: FeedViewModel, useCase: TrendingUseCaseSpy) {
        let useCase = TrendingUseCaseSpy()
        let sut = FeedViewModel(useCase: useCase)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(useCase, file: file, line: line)
        return (sut, useCase)
    }
    
    private func makeItemWithPage(totalCount: Int, count: Int, offset: Int, feed: [Feed]) -> FeedPage {
        FeedPage(totalCount: totalCount, count: count, offset: offset, giphy: feed)
    }
    
    private func makeItem(id: String) -> Feed {
        Feed(id: id, title: "title", datetime: "any time", images: FeedImages(original: FeedImageMetadata(height: "500", width: "500", url: anyURL()), small: FeedImageMetadata(height: "100", width: "100", url: anyURL())), user: FeedUser(username: "test", displayName: "test_name"))
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
