//
//  DataTransferError+ConnectionError.swift
//  Giphy
//
//  Created by Varun on 27/04/23.
//

import Foundation

extension DataTransferError: ConnectionError {
   public var isInternetConnectionError: Bool {
        guard case let DataTransferError.networkError(networkError) = self,
        case NetworkError.notConnected = networkError else {
            return false
        }
        return true
    }
}
