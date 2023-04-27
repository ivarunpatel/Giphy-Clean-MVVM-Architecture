//
//  ConnectionError.swift
//  Giphy
//
//  Created by Varun on 27/04/23.
//

import Foundation

public protocol ConnectionError {
    var isInternetConnectionError: Bool { get }
}

public extension Error {
    var isInternetConnectionError: Bool {
        guard let error = self as? ConnectionError, error.isInternetConnectionError else {
            return false
        }
        return true
    }
}
