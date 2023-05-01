//
//  AppConfiguration.swift
//  GiphyiOSApp
//
//  Created by Varun on 28/04/23.
//

import Foundation

final class AppConfiguration {
    
    lazy var apiKey: String = {
        guard let apiKey = Bundle(for: AppConfiguration.self).object(forInfoDictionaryKey: "ApiKey") as? String else {
            fatalError("ApiKey cannot be empty in info.plist")
        }
        return apiKey
    }()
    
    lazy var baseURL: String = {
        guard let baseURL = Bundle(for: AppConfiguration.self).object(forInfoDictionaryKey: "BaseURL") as? String else {
            fatalError("BaseURL cannot be empty in info.plist")
        }
        return baseURL
    }()
}
