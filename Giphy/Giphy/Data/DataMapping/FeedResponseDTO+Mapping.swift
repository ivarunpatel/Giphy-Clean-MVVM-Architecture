//
//  FeedResponseDTO+Mapping.swift
//  Giphy
//
//  Created by Varun on 19/04/23.
//

import Foundation

// MARK: - Data Transfer Object

public struct FeedResponseDTO: Decodable {
    public let data: [FeedDataDTO]
    public let pagination: FeedPaginationDTO
    
    public init(data: [FeedDataDTO], pagination: FeedPaginationDTO) {
        self.data = data
        self.pagination = pagination
    }
}

public extension FeedResponseDTO {
    struct FeedDataDTO: Decodable {
        let id: String
        let title: String
        let datetime: String
        let images: FeedImagesDTO
        let user: FeedUserDTO?
        
        public init(id: String, title: String, datetime: String, images: FeedImagesDTO, user: FeedUserDTO?) {
            self.id = id
            self.title = title
            self.datetime = datetime
            self.images = images
            self.user = user
        }
        
        enum CodingKeys: String, CodingKey {
            case id
            case title
            case datetime = "trending_datetime"
            case images
            case user
        }
        
        public struct FeedImagesDTO: Decodable {
            let original: FeedImageMetadataDTO
            let small: FeedImageMetadataDTO
            
            public init(original: FeedImageMetadataDTO, small: FeedImageMetadataDTO) {
                self.original = original
                self.small = small
            }
            
            enum CodingKeys: String, CodingKey {
                case original
                case small = "fixed_width_small"
            }
            
            public struct FeedImageMetadataDTO: Decodable {
                let height: String
                let width: String
                let url: URL
                
                public init(height: String, width: String, url: URL) {
                    self.height = height
                    self.width = width
                    self.url = url
                }
            }
        }
        
        public struct FeedUserDTO: Decodable {
            let username: String
            let displayName: String
            
            public init(username: String, displayName: String) {
                self.username = username
                self.displayName = displayName
            }
            
            enum CodingKeys: String, CodingKey {
                case username
                case displayName = "display_name"
            }
        }
    }
    
    struct FeedPaginationDTO: Decodable {
        let totalCount: Int
        let count: Int
        let offset: Int
        
        public init(totalCount: Int, count: Int, offset: Int) {
            self.totalCount = totalCount
            self.count = count
            self.offset = offset
        }
        
        enum CodingKeys: String, CodingKey {
            case totalCount = "total_count"
            case count
            case offset
        }
    }
}

// MARK: - Mappings to Domain
public extension FeedResponseDTO {
    func toDomain() -> FeedPage {
        FeedPage(totalCount: pagination.totalCount, count: pagination.count, offset: pagination.offset, giphy: data.map { $0.toDomain() })
    }
}

extension FeedResponseDTO.FeedDataDTO {
    func toDomain() -> Feed {
        Feed(id: id, title: title, datetime: datetime, images: images.toDomain(), user: user?.toDomain())
    }
}

extension FeedResponseDTO.FeedDataDTO.FeedImagesDTO {
    func toDomain() -> FeedImages {
        FeedImages(original: original.toDomain(), small: small.toDomain())
    }
}

extension FeedResponseDTO.FeedDataDTO.FeedImagesDTO.FeedImageMetadataDTO {
    func toDomain() -> FeedImageMetadata {
        FeedImageMetadata(height: height, width: width, url: url)
    }
}

extension FeedResponseDTO.FeedDataDTO.FeedUserDTO {
    func toDomain() -> FeedUser {
        FeedUser(username: username, displayName: displayName)
    }
}
