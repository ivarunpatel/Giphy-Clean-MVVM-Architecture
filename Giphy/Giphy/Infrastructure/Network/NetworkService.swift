//
//  NetworkService.swift
//  Giphy
//
//  Created by Varun on 18/04/23.
//

import Foundation

public enum NetworkError: Error {
    case error(statusCode: Int, data: Data?)
    case notConnected
    case cancelled
    case generic(Error)
    case urlGeneration
    case unknown
}

public protocol NetworkCancellable {
    func cancel()
}

extension URLSessionDataTask: NetworkCancellable { }

public protocol NetworkService {
    typealias Result = Swift.Result<Data?, NetworkError>
    func request(endpoint: Requestable, completion: @escaping ((Result) -> Void)) -> NetworkCancellable?
}

public class NetworkServiceLoader: NetworkService {
    private let config: NetworkConfigurable
    private let session: URLSession
    
    public init(config: NetworkConfigurable, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }
    
    public func request(endpoint: Requestable, completion: @escaping ((NetworkService.Result) -> Void)) -> NetworkCancellable? {
        do {
            let urlRequest = try endpoint.urlRequest(with: config)
            return request(request: urlRequest, completion: completion)
        } catch {
            completion(.failure(NetworkError.urlGeneration))
            return nil
        }
    }
    
    private func request(request: URLRequest, completion: @escaping ((NetworkService.Result) -> Void)) -> NetworkCancellable {
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                let networkError = self.handle(error: error, with: response, data: data)
                completion(.failure(networkError))
            } else if let data = data, response is HTTPURLResponse {
                completion(.success(data))
            } else {
                completion(.failure(NetworkError.unknown))
            }
        }
        task.resume()
        return task
    }
    
    private func handle(error: Error, with response: URLResponse?, data: Data?) -> NetworkError {
        if let response = response as? HTTPURLResponse {
            return .error(statusCode: response.statusCode, data: data)
        } else {
            return self.resolve(error: error)
        }
    }
    
    private func resolve(error: Error) -> NetworkError {
        let code = URLError.Code(rawValue: (error as NSError).code)
        switch code {
        case .notConnectedToInternet:
            return .notConnected
        case .cancelled:
            return .cancelled
        default:
            return .generic(error)
        }
    }
}
