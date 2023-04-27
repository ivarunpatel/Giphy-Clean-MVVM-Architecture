//
//  TrendingGiphyUseCase.swift
//  Giphy
//
//  Created by Varun on 19/04/23.
//

import Foundation

public protocol TrendingGiphyUseCase {
    func execute(requestValue: TrendingGiphyUseCaseRequestValue, completion: @escaping (Result<GiphyFeedPage, Error>) -> Void) -> Cancellable?
}

public final class TrendingGiphyUseCaseLoader: TrendingGiphyUseCase {
    
    let trendingGiphyRepository: TrendingGiphyRepository
    
    public init(trendingGiphyRepository: TrendingGiphyRepository) {
        self.trendingGiphyRepository = trendingGiphyRepository
    }
    
    public func execute(requestValue: TrendingGiphyUseCaseRequestValue, completion: @escaping (Result<GiphyFeedPage, Error>) -> Void) -> Cancellable? {
        return trendingGiphyRepository.fetchTrendingGiphyList(limit: requestValue.limit) { result in
            switch result {
            case .success(let giphyPage):
                completion(.success(giphyPage))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

public struct TrendingGiphyUseCaseRequestValue {
    let limit: Int
    
    public init(limit: Int) {
        self.limit = limit
    }
}
