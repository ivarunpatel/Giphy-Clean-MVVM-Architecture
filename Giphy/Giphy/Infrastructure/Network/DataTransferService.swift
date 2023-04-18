//
//  DataTransferService.swift
//  Giphy
//
//  Created by Varun on 18/04/23.
//

import Foundation

enum DataTransferError: Error {
    case noResponse
    case parsing(Error)
    case networkError(Error)
}

protocol DataTransferService {
    func request<T: Decodable, E: ResponseRequestable>(with endpoint: E, completion: @escaping (Result<T, DataTransferError>) -> Void) -> NetworkCancellable? where E.Response == T
}

class DataTransferServiceLoader: DataTransferService {
    let networkService: NetworkService
    
    init(networkService: NetworkService) {
        self.networkService = networkService
    }
    
    @discardableResult
    func request<T: Decodable, E: ResponseRequestable>(with endpoint: E, completion: @escaping (Result<T, DataTransferError>) -> Void) -> NetworkCancellable? where E.Response == T {
        networkService.request(endpoint: endpoint) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                let result: Result<T, DataTransferError> = decode(with: endpoint.responseDecoder, data: data)
                completion(result)
            case .failure(let error):
                completion(.failure(.networkError(error)))
            }
        }
    }
    
    private func decode<T: Decodable>(with decoder: ResponseDecoder, data: Data?) -> Result<T, DataTransferError> {
        guard let data = data else {
            return .failure(.noResponse)
        }
        do {
            let responseModel: T = try decoder.decode(data)
            return .success(responseModel)
        } catch {
            return .failure(.parsing(error))
        }
    }
}