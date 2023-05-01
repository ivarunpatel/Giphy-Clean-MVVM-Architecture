//
//  FeedViewModel.swift
//  GiphyiOSApp
//
//  Created by Varun on 01/05/23.
//

import Foundation
import Giphy

public protocol FeedViewModelInput {
    func viewDidLoad()
    func didLoadNextPage()
    func didRefreshFeed()
}

public protocol FeedViewModelOutput {
    var items: Observable<[FeedListItemViewModel]> { get }
    var error: Observable<String> { get }
    var state: Observable<FeedViewModelState?> { get }
}

public enum FeedViewModelState: Equatable {
    case loading
    case nextPage
}

public typealias FeedViewModellable = FeedViewModelInput & FeedViewModelOutput

final public class FeedViewModel: FeedViewModellable {
    
    private let useCase: TrendingUseCase
    
    public init(useCase: TrendingUseCase) {
        self.useCase = useCase
    }
    
    public var items: Observable<[FeedListItemViewModel]> = Observable([])
    public var error: Observable<String> = Observable("")
    public var state: Observable<FeedViewModelState?> = Observable(.none)
    
    private let parPageItem = 10
    private var totalCount = 0
    private var count = 0
    private var offSet = 0
    private var hasMorePage: Bool {
        (count + offSet) < totalCount
    }
    private var pages: [FeedPage] = []
    
    private func loadFeed(state: FeedViewModelState) {
        self.state.value = state
        _ = useCase.execute(requestValue: .init(limit: parPageItem)) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let feedPage):
                appendPage(feedPage: feedPage)
            case .failure(let error):
                handleError(error: error)
            }
            
            self.state.value = .none
        }
    }
    
    private func appendPage(feedPage: FeedPage) {
        totalCount = feedPage.totalCount
        count = feedPage.count
        offSet = feedPage.offset
        
        pages = pages.filter { $0.offset != feedPage.offset } + [feedPage]
        items.value = pages.flatMap { $0.giphy }.map(FeedListItemViewModel.init)
    }
    
    private func resetPages() {
        totalCount = 0
        count = 0
        offSet = 0
        
        pages.removeAll()
        items.value.removeAll()
    }
    
    private func handleError(error: Error) {
        self.error.value = error.isInternetConnectionError ? "No internet connection" : "Failed to load feed"
    }
}

extension FeedViewModel {
    public func viewDidLoad() {
        loadFeed(state: .loading)
    }
    
    public func didLoadNextPage() {
        loadFeed(state: .nextPage)
    }
    
    public func didRefreshFeed() {
        resetPages()
        loadFeed(state: .loading)
    }
}
