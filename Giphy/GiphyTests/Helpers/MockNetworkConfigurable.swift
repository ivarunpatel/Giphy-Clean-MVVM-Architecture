//
//  MockNetworkConfigurable.swift
//  GiphyTests
//
//  Created by Varun on 19/04/23.
//

import Foundation
import Giphy

struct MockNetworkConfigurable: NetworkConfigurable {
    var baseURL: URL = anyURL()
    var headers: [String: String] = [:]
    var queryParameters: [String: String] = [:]
    
    mutating func setbaseURL(url: URL) {
        baseURL = url
    }
    
    mutating func setHeaders(headers: [String: String]) {
        self.headers = headers
    }
    
    mutating func setqueryParameters(queryParameters: [String: String]) {
        self.queryParameters = queryParameters
    }
}
