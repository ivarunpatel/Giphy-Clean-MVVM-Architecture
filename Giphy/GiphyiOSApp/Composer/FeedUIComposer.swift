//
//  FeedUIComposer.swift
//  GiphyiOSApp
//
//  Created by Varun on 05/05/23.
//

import Foundation
import UIKit
import Giphy

public final class FeedUIComposer {
    private init() { }
        
    public static func feedComposed() -> FeedViewController {
        let appConfiguration = AppConfiguration()
        let networkConfiguration = ApiNetworkConfig(baseURL: URL(string: appConfiguration.baseURL)!, headers: [:], queryParameters: ["api_key": appConfiguration.apiKey, "rating": "g"])
        let networkService = NetworkServiceLoader(config: networkConfiguration)
        let dataTransferService = DataTransferServiceLoader(networkService: networkService)
        let trendingRepository = TrendingRepositoryLoader(dataTransferService: dataTransferService)
        let useCase = TrendingUseCaseLoader(trendingGiphyRepository: trendingRepository)
        let gifDataRepository = GifDataRepositoryLoader(dataTransferService: dataTransferService)
        let feedViewModel = FeedViewModel(useCase: useCase, gifDataRepository: gifDataRepository)
        let feedViewController = FeedViewController(viewModel: feedViewModel)
        return feedViewController
    }
}
