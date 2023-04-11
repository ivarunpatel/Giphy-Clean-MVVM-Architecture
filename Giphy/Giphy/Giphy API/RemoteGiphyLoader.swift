//
//  RemoteGiphyLoader.swift
//  Giphy
//
//  Created by Varun on 11/04/23.
//

import Foundation

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (Result<(Data, HTTPURLResponse), Error>) -> Void)
}

public class RemoteGiphyLoader {
    let client: HTTPClient
    let url: URL
    
    public init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public func load(completion: @escaping (Result<[GiphyItem], Error>) -> Void) {
        client.get(from: url) { response in
            switch response {
            case .failure(_):
                completion(.failure(.connectivity))
            default:
                completion(.failure(.invalidData))
            }
        }
    }
}