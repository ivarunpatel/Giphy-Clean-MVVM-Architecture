//
//  GiphyLoader.swift
//  Giphy
//
//  Created by Varun on 11/04/23.
//

import Foundation

protocol GiphyLoader {
    func load(completion: (Result<[GiphyItem], Error>) -> Void)
}
