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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel?.viewDidLoad()
    }
}

final class FeedViewControllerTests: XCTestCase {
    
    func test_loadFeed_requestFeedData() {
        let (sut, useCase) = makeSUT()
        
        sut.loadViewIfNeeded()
        
        XCTAssertEqual(useCase.receivedMessages.count, 1)
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
