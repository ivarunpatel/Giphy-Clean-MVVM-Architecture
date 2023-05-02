//
//  RepositoryTask.swift
//  Giphy
//
//  Created by Varun on 19/04/23.
//

import Foundation

public class RepositoryTask: Cancellable {
    
    public var networkTask: NetworkCancellable?
    public var isCancelled: Bool = false
        
    public init() { }
    
    public func cancel() {
        networkTask?.cancel()
        isCancelled = true
    }
}
