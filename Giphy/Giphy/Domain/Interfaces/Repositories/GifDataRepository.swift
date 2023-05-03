//
//  GifDataRepository.swift
//  Giphy
//
//  Created by Varun on 03/05/23.
//

import Foundation

public protocol GifDataRepository {
    typealias Result = Swift.Result<Data, Error>
    func fetchGif(url: String, completion: @escaping (Result) -> Void) -> Cancellable?
}
