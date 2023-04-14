//
//  Endpoint.swift
//  Giphy
//
//  Created by Varun on 14/04/23.
//

import Foundation

public enum HTTPMethodType: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public protocol Requestable {
    var path: String { get }
    var method: HTTPMethodType { get }
    var queryParameters: [String : Any] { get }
    
    func urlRequest(with config: NetworkConfigurable) throws -> URLRequest
}

public protocol ResponseRequestable: Requestable {
    associatedtype Response
    
    var responseDecoder: ResponseDecoder { get }
}

public protocol ResponseDecoder {
    func decode<T: Decodable>(_ data: Data) throws -> T
}

public enum RequestGenerationError: Error {
    case components
}

extension Requestable {
    func url(with config: NetworkConfigurable) throws -> URL {
        let baseURL = config.baseURL.appending(path: path).absoluteString
        
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw RequestGenerationError.components
        }
        var urlQueryItems = [URLQueryItem]()
        
        config.queryParameters.forEach {
            urlQueryItems.append(URLQueryItem(name: $0.key, value: "\($0.value)"))
        }
        
        urlComponents.queryItems = urlQueryItems.isEmpty ? nil : urlQueryItems
        guard let url = urlComponents.url else {
            throw RequestGenerationError.components
        }
        return url
    }
    public func urlRequest(with config: NetworkConfigurable) throws -> URLRequest {
        let url = try url(with: config)
        var urlRequest = URLRequest(url: url)
        config.headers.forEach { headerField, value in
            urlRequest.setValue(value, forHTTPHeaderField: headerField)
        }
        return urlRequest
    }
}

public class Endpoint<R>: ResponseRequestable {
    public typealias Response = R
    
    public let path: String
    public let method: HTTPMethodType
    public let queryParameters: [String : Any]
    public let responseDecoder: ResponseDecoder
    
    public init(path: String, method: HTTPMethodType, queryParameters: [String : Any] = [:], responseDecoder: ResponseDecoder) {
        self.path = path
        self.method = method
        self.queryParameters = queryParameters
        self.responseDecoder = responseDecoder
    }
}
