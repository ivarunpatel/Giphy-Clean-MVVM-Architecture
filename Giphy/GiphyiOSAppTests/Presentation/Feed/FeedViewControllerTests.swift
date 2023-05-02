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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupRefreshControl()
        bindViewModel()
        viewModel?.viewDidLoad()
    }
    
    private func setupTableView() {
        tableView.dataSource = self
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

extension FeedViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        feedListItemViewModel.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = FeedItemCell()
        cell.configure(with: feedListItemViewModel[indexPath.row])
        return cell
    }
}

final class FeedViewControllerTests: XCTestCase {
    
    func test_loadFeed_requestFeedData() {
        let (sut, useCase) = makeSUT()
        XCTAssertEqual(useCase.receivedMessages.count, 0, "Expected no feed loading request before view is loaded")

        sut.loadViewIfNeeded()
        
        XCTAssertEqual(useCase.receivedMessages.count, 1, "Expected a feed loading request after view is loaded")
    }
    
    func test_loadingFeedIndicator_isVisibleWhileLoadingFeed() {
        let (sut, useCase) = makeSUT()
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
        let feedItem1 = makeItem(title: "Asap Rocky Fashion GIF by E!", datetime: "2023-05-02 11:52:03", originalImageURL: URL(string: "https://media1.giphy.com/media/AqQkbP48FSFM2H8huE/giphy.gif?cid=a73e0a9ddnhiwx199bv5vhla2bxqtb0z6r2lx3dt6axf4ld8&ep=v1_gifs_trending&rid=giphy.gif&ct=g")!, smallImageURL: URL(string: "https://media1.giphy.com/media/AqQkbP48FSFM2H8huE/100w.gif?cid=a73e0a9ddnhiwx199bv5vhla2bxqtb0z6r2lx3dt6axf4ld8&ep=v1_gifs_trending&rid=100w.gif&ct=g")!)
        let feedItem2 = makeItem(title: "Wake Up Morning GIF by Star Wars", datetime: "2019-02-07 10:30:02", originalImageURL: URL(string: "https://media3.giphy.com/media/3ornjVsgtdAWYjQRzy/giphy.gif?cid=a73e0a9ddnhiwx199bv5vhla2bxqtb0z6r2lx3dt6axf4ld8&ep=v1_gifs_trending&rid=giphy.gif&ct=g")!, smallImageURL: URL(string: "https://media3.giphy.com/media/3ornjVsgtdAWYjQRzy/100w.gif?cid=a73e0a9ddnhiwx199bv5vhla2bxqtb0z6r2lx3dt6axf4ld8&ep=v1_gifs_trending&rid=100w.gif&ct=g")!)
        let feedItem3 = makeItem(title: "Happy Teachers Day GIF by DINOSALLY", datetime: "2023-05-02 06:18:08", originalImageURL: URL(string: "https://media4.giphy.com/media/bgmUGSNjILYUasXHMk/giphy.gif?cid=a73e0a9ddnhiwx199bv5vhla2bxqtb0z6r2lx3dt6axf4ld8&ep=v1_gifs_trending&rid=giphy.gif&ct=g")!, smallImageURL: URL(string: "https://media4.giphy.com/media/bgmUGSNjILYUasXHMk/100w.gif?cid=a73e0a9ddnhiwx199bv5vhla2bxqtb0z6r2lx3dt6axf4ld8&ep=v1_gifs_trending&rid=100w.gif&ct=g")!)
        
        var feedPage = FeedPage(totalCount: 3, count: 3, offset: 0, giphy: [feedItem1])
        
        let (sut, useCase) = makeSUT()
        
        sut.loadViewIfNeeded()
        assertThat(sut, isRendering: [])
        
        useCase.complete(with: feedPage, at: 0)
        let feedListItemViewModelOnViewDidLoad = [feedItem1].map(FeedListItemViewModel.init)
        assertThat(sut, isRendering: feedListItemViewModelOnViewDidLoad)
        
        sut.simulateUserInitiatedReload()
        feedPage = FeedPage(totalCount: 3, count: 3, offset: 0, giphy: [feedItem1, feedItem2, feedItem3])
        useCase.complete(with: feedPage, at: 1)
        let feedListItemViewModelAfterReload = [feedItem1, feedItem2, feedItem3].map(FeedListItemViewModel.init)
        assertThat(sut, isRendering: feedListItemViewModelAfterReload)
    }
    
    // MARK: - Helpers
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (viewController: FeedViewController, useCase: TrendingUseCaseSpy) {
        let useCase = TrendingUseCaseSpy()
        let viewModel = FeedViewModel(useCase: useCase)
        let viewController = FeedViewController(viewModel: viewModel)
        trackForMemoryLeaks(useCase, file: file, line: line)
        trackForMemoryLeaks(viewModel, file: file, line: line)
        trackForMemoryLeaks(viewController, file: file, line: line)
        return (viewController, useCase)
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
        let view = sut.feedView(at: index)
        
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
    
    func feedView(at index: Int) -> FeedItemCell? {
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
