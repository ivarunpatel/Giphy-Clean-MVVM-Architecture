//
//  RemoteGiphyLoader.swift
//  Giphy
//
//  Created by Varun on 11/04/23.
//

import Foundation

public protocol HTTPClient {
    func get(from url: URL, completion: (Error) -> Void)
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
    }
    
    public func load(completion: (Error) -> Void = { _ in }) {
        client.get(from: url) { _ in
            completion(.connectivity)
        }
    }
}
