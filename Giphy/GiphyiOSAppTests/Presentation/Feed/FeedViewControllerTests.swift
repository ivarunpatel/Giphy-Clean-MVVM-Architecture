//
//  FeedViewControllerTests.swift
//  GiphyiOSAppTests
//
//  Created by Varun on 01/05/23.
//

import XCTest
import GiphyiOSApp
import Giphy

final class FeedViewController: UIViewController {
    
    private var viewModel: FeedViewModellable?
    
   convenience init(viewModel: FeedViewModellable) {
       self.init()
       self.viewModel = viewModel
    }
    
    var refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel?.viewDidLoad()
        bindViewModel()
    }
    
    private func bindViewModel() {
        viewModel?.state.subscribe(listner: { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .none:
                refreshControl.endRefreshing()
            case .loading:
                refreshControl.beginRefreshing()
            case .nextPage:
                break
            }
        })
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
        
        useCase.complete(with: anyFeedPage())
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator after feed request is completed")
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
    
    private func makeFeedPage(totalCount: Int, count: Int, offset: Int, feed: [Feed]) -> FeedPage {
        FeedPage(totalCount: totalCount, count: count, offset: offset, giphy: feed)
    }
    
    private func makeItem() -> Feed {
        Feed(id: anyRandomId(), title: "title", datetime: "2021-05-21 19:17:34", images: FeedImages(original: FeedImageMetadata(height: "500", width: "500", url: anyURL()), small: FeedImageMetadata(height: "100", width: "100", url: anyURL())), user: FeedUser(username: "test", displayName: "test_name"))
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
    var isShowingLoadingIndicator: Bool {
        refreshControl.isRefreshing
    }
}
