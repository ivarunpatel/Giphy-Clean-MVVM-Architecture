//
//  NetworkConfigurable.swift
//  Giphy
//
//  Created by Varun on 14/04/23.
//

import Foundation

public protocol NetworkConfigurable {
    var baseURL: URL { get }
    var headers: [String: Any] { get }
    var queryParameters: [String: Any] { get }
}
