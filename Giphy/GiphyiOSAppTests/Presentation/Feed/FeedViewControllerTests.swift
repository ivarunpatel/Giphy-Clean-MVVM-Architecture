//
//  FeedViewControllerTests.swift
//  GiphyiOSAppTests
//
//  Created by Varun on 01/05/23.
//

import XCTest
import GiphyiOSApp
import Giphy

final public class FeedItemCell: UITableViewCell {
    let feedImageView: UIImageView = UIImageView()
    let trendingTimeLabel: UILabel = UILabel()
    let titleLabel: UILabel = UILabel()
    let aurthorNameLabel: UILabel = UILabel()
    
    func configure(with model: FeedListItemViewModel) {
        trendingTimeLabel.text = model.trendingDateTime
        titleLabel.text = model.title
        aurthorNameLabel.text = model.aurthorName
        model.didRequestGif()
    }
}

final class FeedViewController: UIViewController {
    
    private var viewModel: FeedViewModellable?
    
   convenience init(viewModel: FeedViewModellable) {
       self.init()
       self.viewModel = viewModel
    }
    
    let tableView = UITableView()
    var refreshControl: UIRefreshControl?
    var feedListItemViewModel = [FeedListItemViewModel]() {
        didSet {
            tableView.reloadData()
        }
    }
    var gifDataRepositoryCancallables = [IndexPath: Cancellable]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupRefreshControl()
        bindViewModel()
        viewModel?.viewDidLoad()
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.prefetchDataSource = self
    }
    
    private func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(didPerformPullToRefresh), for: .valueChanged)
    }
    
    @objc private func didPerformPullToRefresh() {
        viewModel?.didRefreshFeed()
    }
    
    private func bindViewModel() {
        viewModel?.state.subscribe(listner: { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .none:
                refreshControl?.endRefreshing()
            case .loading:
                refreshControl?.beginRefreshing()
            case .nextPage:
                break
            }
        })
        
        viewModel?.items.subscribe(listner: { [weak self] feedItems in
            guard let self = self else { return }
            feedListItemViewModel = feedItems
        })
    }
}

extension FeedViewController: UITableViewDataSource, UITableViewDelegate, UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        feedListItemViewModel.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = FeedItemCell()
        let feedListItemViewModel = feedListItemViewModel[indexPath.row]
        cell.configure(with: feedListItemViewModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let feedListItemViewModel = feedListItemViewModel[indexPath.row]
        feedListItemViewModel.didCancelImageRequest()
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            let feedListItemViewModel = feedListItemViewModel[indexPath.row]
            feedListItemViewModel.didRequestGif()
        }
    }
}

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
        let feedItem1 = makeItem(title: "Title 1", datetime: "2023-05-02 11:52:03", originalImageURL: URL(string: "http://url-0-0.com")!, smallImageURL: URL(string: "http://url-0-1.com")!)
        let feedItem2 = makeItem(title: "Title 2", datetime: "2019-02-07 10:30:02", originalImageURL: URL(string: "http://url-1-0.com")!, smallImageURL: URL(string: "http://url-1-1.com")!)
        let feedItem3 = makeItem(title: "Title 3", datetime: "2023-05-02 06:18:08", originalImageURL: URL(string: "http://url-2-0.com")!, smallImageURL: URL(string: "http://url-2-1.com")!)
        
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
    
    func test_feedItemCell_loadGifURLWhenVisible() {
        let feedItem1 = makeItem(title: "Title 1", datetime: "2023-05-02 11:52:03", originalImageURL: URL(string: "http://url-0-0.com")!, smallImageURL: URL(string: "http://url-0-1.com")!)
        let feedItem2 = makeItem(title: "Title 2", datetime: "2019-02-07 10:30:02", originalImageURL: URL(string: "http://url-1-0.com")!, smallImageURL: URL(string: "http://url-1-1.com")!)
        let feedPage = FeedPage(totalCount: 3, count: 3, offset: 0, giphy: [feedItem1, feedItem2])

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
        let feedItem1 = makeItem(title: "Title 1", datetime: "2023-05-02 11:52:03", originalImageURL: URL(string: "http://url-0-0.com")!, smallImageURL: URL(string: "http://url-0-1.com")!)
        let feedItem2 = makeItem(title: "Title 2", datetime: "2019-02-07 10:30:02", originalImageURL: URL(string: "http://url-1-0.com")!, smallImageURL: URL(string: "http://url-1-1.com")!)
        let feedPage = FeedPage(totalCount: 3, count: 3, offset: 0, giphy: [feedItem1, feedItem2])
        
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
        let feedItem1 = makeItem(title: "Title 1", datetime: "2023-05-02 11:52:03", originalImageURL: URL(string: "http://url-0-0.com")!, smallImageURL: URL(string: "http://url-0-1.com")!)
        let feedItem2 = makeItem(title: "Title 2", datetime: "2019-02-07 10:30:02", originalImageURL: URL(string: "http://url-1-0.com")!, smallImageURL: URL(string: "http://url-1-1.com")!)
        let feedPage = FeedPage(totalCount: 3, count: 3, offset: 0, giphy: [feedItem1, feedItem2])
        
        let (sut, useCase, gifDataRepository) = makeSUT()
        
        sut.loadViewIfNeeded()
        
        useCase.complete(with: feedPage)
        XCTAssertTrue(gifDataRepository.loadedGifURLs.isEmpty, "Expected no gif URL requests untill image is near visible")
        
        sut.simulateFeedCellNearVisible(at: 0)
        XCTAssertEqual(gifDataRepository.loadedGifURLs, [feedItem1.images.small.url], "Expected first gif URL request once first feeditemcell is near visible")
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
        var loadedGifURLs = [URL]()
        var cancelledGifURLs = [URL]()
        
        func fetchGif(url: String, completion: @escaping (GifDataRepository.Result) -> Void) -> Cancellable? {
            loadedGifURLs.append(URL(string: url)!)
            return CancellableSpy { [weak self] in
                self?.cancelledGifURLs.append(URL(string: url)!)
            }
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
    func simulateFeedCellNotVisible(at index: Int) -> FeedItemCell? {
        let cell = feedCell(at: index)
        
        let delegate = tableView.delegate
        let indexPath = IndexPath(item: index, section: feedViewSection)
        delegate?.tableView?(tableView, didEndDisplaying: cell!, forRowAt: indexPath)
        return cell
    }
    
    func simulateFeedCellNearVisible(at index: Int) {
        let prefetchDataSource = tableView.prefetchDataSource
        let indexPath = IndexPath(row: index, section: feedViewSection)
        prefetchDataSource?.tableView(tableView, prefetchRowsAt: [indexPath])
    }
    
    func feedCell(at index: Int) -> FeedItemCell? {
        let dataSource = tableView.dataSource
        let indexPath = IndexPath(item: index, section: feedViewSection)
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