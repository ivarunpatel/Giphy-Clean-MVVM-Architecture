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
}

final class FeedViewModelTests: XCTestCase {
    
    func test_init_doesNotLoadItems() {
        let useCase = TrendingUseCaseSpy()
        let sut = FeedViewModel(useCase: useCase)
        
        XCTAssertTrue(useCase.receivedMessages.isEmpty)
    }
    
    // MARK: - Helpers
    
    private final class TrendingUseCaseSpy: TrendingUseCase {
        public private(set) var receivedMessages = [(Result<FeedPage, Error>) -> Void]()
        
        func execute(requestValue: TrendingGiphyUseCaseRequestValue, completion: @escaping (Result<FeedPage, Error>) -> Void) -> Cancellable? {
            return nil
        }
    }

}
