//
//  FeedViewControllerTests.swift
//  GiphyiOSAppTests
//
//  Created by Varun on 01/05/23.
//

import XCTest
import GiphyiOSApp
import Giphy

final class FeedViewControllerTests: XCTestCase {
    
    func test_loadFeed_requestFeedData() {
        let (sut, useCase, _) = makeSUT()
        XCTAssertEqual(useCase.receivedMessages.count, 0, "Expected no feed loading request before view is loaded")
        
        sut.loadViewIfNeeded()
        
        XCTAssertEqual(useCase.receivedMessages.count, 1, "Expected a feed loading request after view is loaded")
    }
    
    func test_loadingFeedIndicator_isVisibleWhileLoadingFeed() {
        let (sut, useCase, _) = makeSUT()
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator before view is loaded")
        
        sut.loadViewIfNeeded()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator after view is loaded")
        
        useCase.complete(with: anyFeedPage(), at: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator after feed request is completed")
        
        sut.simulateUserInitiatedReload()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator on user initiated feed reload")
        
        useCase.complete(with: anyFeedPage(), at: 1)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator user initiated feed reload is completed")
    }
    
    func test_loadFeedCompletion_rendersSuccessfullyLoadedFeed() {
        let feedItem1 = makeItem()
        let feedItem2 = makeItem()
        let feedItem3 = makeItem()
        
        var feedPage = FeedPage(totalCount: 3, count: 3, offset: 0, giphy: [feedItem1])
        
        let (sut, useCase, gifDataRepository) = makeSUT()
        
        sut.loadViewIfNeeded()
        assertThat(sut, isRendering: [])
        
        useCase.complete(with: feedPage, at: 0)
        let feedListItemViewModelOnViewDidLoad = [feedItem1].map { feed in
            FeedListItemViewModel(feed: feed, gifDataRepository: gifDataRepository)
        }
        assertThat(sut, isRendering: feedListItemViewModelOnViewDidLoad)
        
        sut.simulateUserInitiatedReload()
        feedPage = FeedPage(totalCount: 3, count: 3, offset: 0, giphy: [feedItem1, feedItem2, feedItem3])
        useCase.complete(with: feedPage, at: 1)
        let feedListItemViewModelAfterReload = [feedItem1, feedItem2, feedItem3].map { feed in
            FeedListItemViewModel(feed: feed, gifDataRepository: gifDataRepository)
        }
        assertThat(sut, isRendering: feedListItemViewModelAfterReload)
    }
    
    func test_feedItemCell_rendersSuccessfullyLoadedFeedsAfterNonEmptyFeed() {
        let feedItem1 = makeItem()
        let feedItem2 = makeItem()
        
        var feedPage = FeedPage(totalCount: 3, count: 3, offset: 0, giphy: [feedItem1, feedItem2])
        
        let (sut, useCase, gifDataRepository) = makeSUT()
        sut.loadViewIfNeeded()
        assertThat(sut, isRendering: [])
        
        useCase.complete(with: feedPage, at: 0)
        
        let feedListItemViewModelOnViewDidLoad = [feedItem1, feedItem2].map { feed in
            FeedListItemViewModel(feed: feed, gifDataRepository: gifDataRepository)
        }
        assertThat(sut, isRendering: feedListItemViewModelOnViewDidLoad)
        
        sut.simulateUserInitiatedReload()
        feedPage = FeedPage(totalCount: 3, count: 3, offset: 0, giphy: [])
        useCase.complete(with: feedPage, at: 1)
        
        assertThat(sut, isRendering: [])
    }
    
    func test_feedItemCell_displaySuccessfullyLoadedGif() {
        let feedItem1 = makeItem()
        let feedItem2 = makeItem()
        let feedPage = FeedPage(totalCount: 2, count: 2, offset: 0, giphy: [feedItem1, feedItem2])
        
        let (sut, useCase, gifDataRepository) = makeSUT()
        sut.loadViewIfNeeded()
        assertThat(sut, isRendering: [])
        
        useCase.complete(with: feedPage, at: 0)
        
        let firstFeedItemCell = sut.feedCell(at: 0)
        XCTAssertNil(firstFeedItemCell?.feedImageView.image, "Expected no gif untill first GIF URL request does not complete successfully")
        
        let firstGifData = try? Data(contentsOf: URL(string: "https://media2.giphy.com/media/OHq7yCqf9H1mR9LinC/100w.gif?cid=a73e0a9df6psn43cpb0bqspv0wfl9qs0x22k2kizl0k7fqa2&ep=v1_gifs_trending&rid=100w.gif&ct=g")!)
        gifDataRepository.complete(with: firstGifData!, at: 0)
        
        let firstGif = UIImage.gifImageWithData(firstGifData!)
        XCTAssertEqual(firstFeedItemCell?.feedImageView.image?.pngData(), firstGif?.pngData(), "Expected first gif loaded successfully")
        
        
        let secondFeedItemCell = sut.feedCell(at: 1)
        XCTAssertNil(secondFeedItemCell?.feedImageView.image, "Expected no gif untill second GIF URL request does not complete successfully")
        
        let secondGifData = try? Data(contentsOf: URL(string: "https://media1.giphy.com/media/DsIiN6pX74mlhmNjeZ/100w.gif?cid=a73e0a9df6psn43cpb0bqspv0wfl9qs0x22k2kizl0k7fqa2&ep=v1_gifs_trending&rid=100w.gif&ct=g")!)
        gifDataRepository.complete(with: secondGifData!, at: 1)
        
        let secondGif = UIImage.gifImageWithData(secondGifData!)
        XCTAssertEqual(secondFeedItemCell?.feedImageView.image?.pngData(), secondGif?.pngData(), "Expected second gif loaded successfully")
    }
    
    func test_feedItemCell_doesNotDisplayGifOnFailedGifLoading() {
        let feedItem1 = makeItem()
        let feedItem2 = makeItem()
        
        let feedPage = FeedPage(totalCount: 2, count: 2, offset: 0, giphy: [feedItem1, feedItem2])
        
        let (sut, useCase, gifDataRepository) = makeSUT()
        sut.loadViewIfNeeded()
        assertThat(sut, isRendering: [])
        
        useCase.complete(with: feedPage, at: 0)
        
        let firstFeedItemCell = sut.feedCell(at: 0)
        
        gifDataRepository.complete(with: anyNSError(), at: 0)
        XCTAssertNil(firstFeedItemCell?.feedImageView.image, "Expected no gif when first GIF URL request completes with error")
        
        let secondFeedItemCell = sut.feedCell(at: 1)
        
        gifDataRepository.complete(with: anyNSError(), at: 1)
        XCTAssertNil(secondFeedItemCell?.feedImageView.image, "Expected no gif when second GIF URL request completes with error")
    }
    
    func test_feedItemCell_loadGifURLWhenVisible() {
        let feedItem1 = makeItem(smallImageURL: URL(string: "http://url-0-1.com")!)
        let feedItem2 = makeItem(smallImageURL: URL(string: "http://url-1-1.com")!)
        let feedPage = FeedPage(totalCount: 2, count: 2, offset: 0, giphy: [feedItem1, feedItem2])
        
        let (sut, useCase, gifDataRepository) = makeSUT()
        
        sut.loadViewIfNeeded()
        
        useCase.complete(with: feedPage)
        
        XCTAssertTrue(gifDataRepository.loadedGifURLs.isEmpty, "Expected no Gif URL requests until view become visible")
        
        sut.simulateFeedCellVisible(at: 0)
        XCTAssertEqual(gifDataRepository.loadedGifURLs, [feedItem1.images.small.url], "Expected one Gif URL requests after first view become visible")
        
        sut.simulateFeedCellVisible(at: 1)
        XCTAssertEqual(gifDataRepository.loadedGifURLs, [feedItem1.images.small.url, feedItem2.images.small.url], "Expected two Gif URL requests after second view become visible")
    }
    
    func test_feedItemCell_cancelsGifLoadingWhenNotVisibleAnymore() {
        let feedItem1 = makeItem(smallImageURL: URL(string: "http://url-0-1.com")!)
        let feedItem2 = makeItem(smallImageURL: URL(string: "http://url-1-1.com")!)
        let feedPage = FeedPage(totalCount: 2, count: 2, offset: 0, giphy: [feedItem1, feedItem2])
        
        let (sut, useCase, gifDataRepository) = makeSUT()
        
        sut.loadViewIfNeeded()
        
        useCase.complete(with: feedPage)
        XCTAssertTrue(gifDataRepository.cancelledGifURLs.isEmpty, "Expected no cancelled gif url before view is not become invisible")
        
        sut.simulateFeedCellNotVisible(at: 0)
        XCTAssertEqual(gifDataRepository.cancelledGifURLs, [feedItem1.images.small.url], "Expected one cancelled gif url after first view is not visible anymore")
        
        sut.simulateFeedCellNotVisible(at: 1)
        XCTAssertEqual(gifDataRepository.cancelledGifURLs, [feedItem1.images.small.url, feedItem2.images.small.url], "Expected two cancelled gif url after second view is not visible anymore")
    }
    
    func test_feedItemCell_preloadsGifURLWhenNearVisible() {
        let feedItem1 = makeItem(smallImageURL: URL(string: "http://url-0-1.com")!)
        let feedItem2 = makeItem(smallImageURL: URL(string: "http://url-1-1.com")!)
        let feedPage = FeedPage(totalCount: 2, count: 2, offset: 0, giphy: [feedItem1, feedItem2])
        
        let (sut, useCase, gifDataRepository) = makeSUT()
        
        sut.loadViewIfNeeded()
        
        useCase.complete(with: feedPage)
        XCTAssertTrue(gifDataRepository.loadedGifURLs.isEmpty, "Expected no gif URL requests untill feeditemcell is near visible")
        
        sut.simulateFeedCellNearVisible(at: 0)
        XCTAssertEqual(gifDataRepository.loadedGifURLs, [feedItem1.images.small.url], "Expected one gif URL request once first feeditemcell is near visible")
        
        sut.simulateFeedCellNearVisible(at: 1)
        XCTAssertEqual(gifDataRepository.loadedGifURLs, [feedItem1.images.small.url, feedItem2.images.small.url], "Expected two gif URL request once second feeditemcell is near visible")
    }
    
    func test_feedItemCell_cancelPreloadingGifURLWhenNotNearVisible() {
        let feedItem1 = makeItem(smallImageURL: URL(string: "http://url-0-1.com")!)
        let feedItem2 = makeItem(smallImageURL: URL(string: "http://url-1-1.com")!)
        let feedPage = FeedPage(totalCount: 2, count: 2, offset: 0, giphy: [feedItem1, feedItem2])
        
        let (sut, useCase, gifDataRepository) = makeSUT()
        
        sut.loadViewIfNeeded()
        
        useCase.complete(with: feedPage)
        XCTAssertTrue(gifDataRepository.cancelledGifURLs.isEmpty, "Expected no gif cancelled URL requests untill feeditemcell is not near visible")
        
        sut.simulateFeedCellNotNearVisible(at: 0)
        XCTAssertEqual(gifDataRepository.cancelledGifURLs, [feedItem1.images.small.url], "Expected one gif URL request once first feeditemcell is not near visible")
        
        sut.simulateFeedCellNotNearVisible(at: 1)
        XCTAssertEqual(gifDataRepository.cancelledGifURLs, [feedItem1.images.small.url, feedItem2.images.small.url], "Expected two gif URL request once second feeditemcell is not near visible")
    }
    
    func test_feedItemCell_shouldLoadNextPageWhenLastItemIsNearToVisible() {
        let feedItem1 = makeItem()
        let feedItem2 = makeItem()
        var feedPage = FeedPage(totalCount: 3, count: 2, offset: 0, giphy: [feedItem1, feedItem2])
        
        let (sut, useCase, _) = makeSUT()
        
        sut.loadViewIfNeeded()
        
        useCase.complete(with: feedPage)
        
        sut.simlateFeedCellIsNearToVisible(at: 1)
        
        let feedItem3 = makeItem()
        feedPage = FeedPage(totalCount: 3, count: 1, offset: 1, giphy: [feedItem3])
        
        useCase.complete(with: feedPage)
        
        XCTAssertEqual(sut.numberOfRenderedFeedViews(), 3)
    }
    
    func test_feedItemCell_doesNotRenderLoadedGifWhenNotVisibleAnymore() {
        let feedItem = makeItem()
        let feedPage = FeedPage(totalCount: 3, count: 2, offset: 0, giphy: [feedItem])
        
        let (sut, useCase, gifDataRepository) = makeSUT()
        
        sut.loadViewIfNeeded()
        
        useCase.complete(with: feedPage)
        let feedItemCell = sut.simulateFeedCellNotVisible(at: 0)
        
        let gifData = try? Data(contentsOf: URL(string: "https://media2.giphy.com/media/OHq7yCqf9H1mR9LinC/100w.gif?cid=a73e0a9df6psn43cpb0bqspv0wfl9qs0x22k2kizl0k7fqa2&ep=v1_gifs_trending&rid=100w.gif&ct=g")!)
        gifDataRepository.complete(with: gifData!)
        
        XCTAssertNil(feedItemCell?.feedImageView.image, "Expected no rendered gif when gif loading completed after FeedItemCell is not visible anymore")
    }
    
    // MARK: - Helpers
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (viewController: FeedViewController, useCase: TrendingUseCaseSpy, gifDataRepository: GifDataRepositorySpy) {
        let useCase = TrendingUseCaseSpy()
        let gifDataRepository = GifDataRepositorySpy()
        let viewModel = FeedViewModel(useCase: useCase, gifDataRepository: gifDataRepository)
        let viewController = FeedViewController(viewModel: viewModel)
        trackForMemoryLeaks(useCase, file: file, line: line)
        trackForMemoryLeaks(viewModel, file: file, line: line)
        trackForMemoryLeaks(gifDataRepository, file: file, line: line)
        trackForMemoryLeaks(viewController, file: file, line: line)
        return (viewController, useCase, gifDataRepository)
    }
    
    private func assertThat(_ sut: FeedViewController, isRendering feed: [FeedListItemViewModel], file: StaticString = #file, line: UInt = #line) {
        sut.tableView.layoutIfNeeded()
        RunLoop.main.run(until: Date())
        
        guard sut.numberOfRenderedFeedViews() == feed.count else {
            return XCTFail("Expected \(feed.count) feed view, got \(sut.numberOfRenderedFeedViews()) instead", file: file, line: line)
        }
        
        feed.enumerated().forEach { index, item in
            assertThat(sut, feed: item, at: index, file: file, line: line)
        }
    }
    
    private func assertThat(_ sut: FeedViewController, feed: FeedListItemViewModel, at index: Int, file: StaticString = #file, line: UInt = #line) {
        let view = sut.feedCell(at: index)
        
        XCTAssertEqual(view?.titleLabel.text, feed.title, "Expected title to be \(feed.title) for feed view at \(index)", file: file, line: line)
        
        XCTAssertEqual(view?.trendingTimeLabel.text, feed.trendingDateTime, "Expected trending datetime to be \(feed.title) for feed view at \(index)", file: file, line: line)
        
        XCTAssertEqual(view?.aurthorNameLabel.text, feed.aurthorName, "Expected aurthor to be \(feed.title) for feed view at \(index)", file: file, line: line)
    }
    
    private func makeFeedPage(totalCount: Int, count: Int, offset: Int, feed: [Feed]) -> FeedPage {
        FeedPage(totalCount: totalCount, count: count, offset: offset, giphy: feed)
    }
    
    private func makeItem(title: String = "title", datetime: String? = "2021-05-21 19:17:34", originalImageURL: URL = anyURL(), smallImageURL: URL = anyURL()) -> Feed {
        Feed(id: anyRandomId(), title: title, datetime: datetime, images: FeedImages(original: FeedImageMetadata(height: "500", width: "500", url: originalImageURL), small: FeedImageMetadata(height: "100", width: "100", url: smallImageURL)), user: FeedUser(username: "test", displayName: "test_name"))
    }
    
    private func anyFeedPage() -> FeedPage {
        makeFeedPage(totalCount: 5, count: 2, offset: 0, feed: [makeItem()])
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
    
    private class GifDataRepositorySpy: GifDataRepository {
        var receivedMessages = [(url: String, completion: (GifDataRepository.Result) -> Void)]()
        var loadedGifURLs: [URL] {
            receivedMessages.map { URL(string: $0.url)! }
        }
        var cancelledGifURLs = [URL]()
        
        func fetchGif(url: String, completion: @escaping (GifDataRepository.Result) -> Void) -> Cancellable? {
            receivedMessages.append((url, completion))
            return CancellableSpy { [weak self] in
                self?.cancelledGifURLs.append(URL(string: url)!)
            }
        }
        
        func complete(with data: Data, at index: Int = 0) {
            receivedMessages[index].completion(.success(data))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            receivedMessages[index].completion(.failure(error))
        }
        
        private struct CancellableSpy: Cancellable {
            let cancelCallBlock: () -> Void
            func cancel() {
                cancelCallBlock()
            }
        }
    }
}

extension FeedViewController {
    func simulateUserInitiatedReload() {
        refreshControl?.simulatePullToRefresh()
    }
    
    var isShowingLoadingIndicator: Bool {
        refreshControl?.isRefreshing == true
    }
    
    func numberOfRenderedFeedViews() -> Int {
        tableView.numberOfRows(inSection: feedViewSection)
    }
    
    @discardableResult
    func simulateFeedCellVisible(at index: Int) -> FeedItemCell? {
        feedCell(at: index)
    }
    
    @discardableResult
    func simulateFeedCellNotVisible(at row: Int) -> FeedItemCell? {
        let cell = feedCell(at: row)
        
        let delegate = tableView.delegate
        let indexPath = IndexPath(item: row, section: feedViewSection)
        delegate?.tableView?(tableView, didEndDisplaying: cell!, forRowAt: indexPath)
        return cell
    }
    
    func simulateFeedCellNearVisible(at row: Int) {
        let prefetchDataSource = tableView.prefetchDataSource
        let indexPath = IndexPath(row: row, section: feedViewSection)
        prefetchDataSource?.tableView(tableView, prefetchRowsAt: [indexPath])
    }
    
    func simulateFeedCellNotNearVisible(at row: Int) {
        simulateFeedCellNearVisible(at: row)
        
        let prefetchDataSource = tableView.prefetchDataSource
        let indexPath = IndexPath(row: row, section: feedViewSection)
        prefetchDataSource?.tableView?(tableView, cancelPrefetchingForRowsAt: [indexPath])
    }
    
    func simlateFeedCellIsNearToVisible(at row: Int) {
        let cell = feedCell(at: row)

        let delegate = tableView.delegate
        let indexPath = IndexPath(row: row, section: feedViewSection)
        delegate?.tableView?(tableView, willDisplay: cell!, forRowAt: indexPath)
    }
    
    func feedCell(at row: Int) -> FeedItemCell? {
        let dataSource = tableView.dataSource
        let indexPath = IndexPath(item: row, section: feedViewSection)
        return dataSource?.tableView(tableView, cellForRowAt: indexPath) as? FeedItemCell
    }
    
    private var feedViewSection: Int {
        0
    }
    
}

extension UIRefreshControl {
    func simulatePullToRefresh() {
        self.allTargets.forEach { target in
            self.actions(forTarget: target, forControlEvent: .valueChanged)?.forEach({ action in
                (target as NSObject).perform(Selector(action))
            })
        }
    }
}

struct SomeServiceStub {
    var stub: Feed?
    func getFeed() async throws -> Feed {
        if let stub = stub {
            return stub
        } else {
            throw NetworkError.unknown
        }
    }
}
