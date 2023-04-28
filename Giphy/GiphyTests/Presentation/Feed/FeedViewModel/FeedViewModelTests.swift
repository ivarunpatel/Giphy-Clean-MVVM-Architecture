//
//  FeedViewModelTests.swift
//  GiphyTests
//
//  Created by Varun on 27/04/23.
//

import XCTest
import Giphy

public struct FeedListItemViewModel: Equatable {
    public let id: String
    public let title: String
    public private(set) var datetime: String = ""
    public let images: FeedImages
    public let user: FeedUser?
    
    public init(feed: Feed) {
        id = feed.id
        title = feed.title
        images = feed.images
        user = feed.user
        datetime = formatDateTime(datetime: feed.datetime)
    }
    
    private func formatDateTime(datetime: String) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        if let date = dateFromString(dateTime: datetime) {
            return formatter.localizedString(for: date, relativeTo: Date())
        } else {
            return "Invalid Date"
        }
    }
    
    private func dateFromString(dateTime: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        return dateFormatter.date(from: dateTime)
    }
}

final class FeedViewModel {
    
    let useCase: TrendingUseCase
    
    init(useCase: TrendingUseCase) {
        self.useCase = useCase
    }
    
    var items: Observable<[FeedListItemViewModel]> = Observable([])
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
                appendPage(feedPage: feedPage)
            case .failure(let error):
                handleError(error: error)
            }
        }
    }
    
    private func appendPage(feedPage: FeedPage) {
        totalCount = feedPage.totalCount
        count = feedPage.count
        offSet = feedPage.offset
        
        pages = pages.filter { $0.offset != feedPage.offset } + [feedPage]
        items.value = pages.flatMap { $0.giphy }.map(FeedListItemViewModel.init)
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
        
        let (feed, feedListItemViewModel) = makeItem(id: "123")
        let feedPage = makeItemWithPage(totalCount: 5, count: 2, offset: 0, feed: [feed])
        useCase.complete(with: feedPage)
        
        XCTAssertEqual(sut.items.value, [feedListItemViewModel])
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

        let (feed1, feedListItemViewModel1) = makeItem(id: "123")
        let (feed2, feedListItemViewModel2) = makeItem(id: "456")
        let firstPageItems = makeItemWithPage(totalCount: 4, count: 2, offset: 0, feed: [feed1, feed2])
        useCase.complete(with: firstPageItems)

        XCTAssertEqual(sut.items.value, [feedListItemViewModel1, feedListItemViewModel2])

        sut.didLoadNextPage()

        let (feed3, feedListItemViewModel3) = makeItem(id: "789")
        let (feed4, feedListItemViewModel4) = makeItem(id: "101112")
        let secondPageItems = makeItemWithPage(totalCount: 4, count: 2, offset: 2, feed: [feed3, feed4])
        useCase.complete(with: secondPageItems)

        XCTAssertEqual(sut.items.value, [feedListItemViewModel1, feedListItemViewModel2, feedListItemViewModel3, feedListItemViewModel4])
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
    
    private func makeItem(id: String) -> (Feed, FeedListItemViewModel) {
        let feed = Feed(id: id, title: "title", datetime: "2021-05-21 19:17:34", images: FeedImages(original: FeedImageMetadata(height: "500", width: "500", url: anyURL()), small: FeedImageMetadata(height: "100", width: "100", url: anyURL())), user: FeedUser(username: "test", displayName: "test_name"))
        let feedListItemViewModel = FeedListItemViewModel(feed: feed)
        return (feed, feedListItemViewModel)
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
