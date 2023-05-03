//
//  GifDataRepositoryLoader.swift
//  Giphy
//
//  Created by Varun on 03/05/23.
//

import Foundation

final public class GifDataRepositoryLoader: GifDataRepository {
    
    private let dataTransferService: DataTransferService
    
    public init(dataTransferService: DataTransferService) {
        self.dataTransferService = dataTransferService
    }
    
    public func fetchGif(url: String, completion: @escaping (GifDataRepository.Result) -> Void) -> Cancellable? {
        let endPoint = Endpoint<Data>(path: url, isFullPath: true, method: .get, responseDecoder: RawDataResponseDecoder())
        
        let task = RepositoryTask()
        task.networkTask = dataTransferService.request(with: endPoint, completion: { result in
            let mappedResult = result.mapError { $0 as Error }
            completion(mappedResult)
        })
        return task
    }
}
