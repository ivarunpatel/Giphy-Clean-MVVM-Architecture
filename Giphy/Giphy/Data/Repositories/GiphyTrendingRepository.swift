//
//  GiphyTrendingRepository.swift
//  Giphy
//
//  Created by Varun on 19/04/23.
//

import Foundation

public final class GiphyTrendingRepository: TrendingGiphyRepository {
    
    let dataTransferService: DataTransferService
    
    public init(dataTransferService: DataTransferService) {
        self.dataTransferService = dataTransferService
    }
    
    public func fetchTrendingGiphyList(limit: Int, completion: @escaping (TrendingGiphyRepository.Result) -> Void) -> Cancellable? {
        let task = RepositoryTask()
        

        let endpoint = Endpoint<GiphyResponseDTO>(path: "/v1/gifs/trending", method: .get)
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
