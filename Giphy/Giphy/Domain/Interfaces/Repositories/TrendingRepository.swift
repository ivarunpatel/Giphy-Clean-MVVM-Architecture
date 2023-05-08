//
//  TrendingRepository.swift
//  Giphy
//
//  Created by Varun on 19/04/23.
//

import Foundation

public protocol TrendingRepository {
    typealias Result = Swift.Result<FeedPage, Error>
    func fetchTrendingGiphyList(limit: Int, offset: Int, completion: @escaping (Result) -> Void) -> Cancellable?
}
