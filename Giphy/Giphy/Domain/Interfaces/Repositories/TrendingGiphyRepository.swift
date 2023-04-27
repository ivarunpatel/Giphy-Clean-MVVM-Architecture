//
//  TrendingGiphyRepository.swift
//  Giphy
//
//  Created by Varun on 19/04/23.
//

import Foundation

public protocol TrendingGiphyRepository {
    typealias Result = Swift.Result<GiphyFeedPage, Error>
    func fetchTrendingGiphyList(limit: Int, completion: @escaping (Result) -> Void) -> Cancellable?
}
