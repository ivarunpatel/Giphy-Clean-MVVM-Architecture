//
//  TrendingUseCase.swift
//  Giphy
//
//  Created by Varun on 19/04/23.
//

import Foundation

public protocol TrendingUseCase {
    func execute(requestValue: TrendingGiphyUseCaseRequestValue, completion: @escaping (Result<FeedPage, Error>) -> Void) -> Cancellable?
}

public final class TrendingUseCaseLoader: TrendingUseCase {
    
    let trendingGiphyRepository: TrendingRepository
    
    public init(trendingGiphyRepository: TrendingRepository) {
        self.trendingGiphyRepository = trendingGiphyRepository
    }
    
    public func execute(requestValue: TrendingGiphyUseCaseRequestValue, completion: @escaping (Result<FeedPage, Error>) -> Void) -> Cancellable? {
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
