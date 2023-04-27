//
//  TrendingRepositoryLoader.swift
//  Giphy
//
//  Created by Varun on 19/04/23.
//

import Foundation

public final class TrendingRepositoryLoader: TrendingRepository {
    
    let dataTransferService: DataTransferService
    
    public init(dataTransferService: DataTransferService) {
        self.dataTransferService = dataTransferService
    }
    
    public func fetchTrendingGiphyList(limit: Int, completion: @escaping (TrendingRepository.Result) -> Void) -> Cancellable? {
        let task = RepositoryTask()
        

        let endpoint = Endpoint<FeedResponseDTO>(path: "/v1/gifs/trending", method: .get, queryParameters: ["limit": limit, "rating": "g"])
        task.networkTask =  dataTransferService.request(with: endpoint) { result in
            switch result {
            case .success(let responseModel):
                completion(.success(responseModel.toDomain()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
        return task
    }
}
