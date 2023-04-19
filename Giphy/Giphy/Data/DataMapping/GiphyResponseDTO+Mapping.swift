//
//  GiphyResponseDTO+Mapping.swift
//  Giphy
//
//  Created by Varun on 19/04/23.
//

import Foundation

// MARK: - Data Transfer Object

public struct GiphyResponseDTO: Decodable {
    public let data: [GiphyDataDTO]
    public let pagination: PaginationDTO
    
    public init(data: [GiphyDataDTO], pagination: PaginationDTO) {
        self.data = data
        self.pagination = pagination
    }
}

public extension GiphyResponseDTO {
    struct GiphyDataDTO: Decodable {
        let id: String
        let title: String
        let datetime: String
        let images: GiphyImagesDTO
        
        public init(id: String, title: String, datetime: String, images: GiphyImagesDTO) {
            self.id = id
            self.title = title
            self.datetime = datetime
            self.images = images
        }
        
        enum CodingKeys: String, CodingKey {
            case id
            case title
            case datetime = "import_datetime"
            case images
        }
        
        public struct GiphyImagesDTO: Decodable {
            let original: GiphyImageMetadataDTO
            let small: GiphyImageMetadataDTO
            
            public init(original: GiphyImageMetadataDTO, small: GiphyImageMetadataDTO) {
                self.original = original
                self.small = small
            }
            
            enum CodingKeys: String, CodingKey {
                case original
                case small = "fixed_width_small"
            }
            
            public struct GiphyImageMetadataDTO: Decodable {
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
    }
    
    struct PaginationDTO: Decodable {
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
public extension GiphyResponseDTO {
    func toDomain() -> GiphyPage {
        GiphyPage(totalCount: pagination.totalCount, count: pagination.count, offset: pagination.offset, giphy: data.map { $0.toDomain() })
    }
}

extension GiphyResponseDTO.GiphyDataDTO {
    func toDomain() -> Giphy {
        Giphy(id: id, title: title, datetime: datetime, images: images.toDomain())
    }
}

extension GiphyResponseDTO.GiphyDataDTO.GiphyImagesDTO {
    func toDomain() -> GiphyImages {
        GiphyImages(original: original.toDomain(), small: small.toDomain())
    }
}

extension GiphyResponseDTO.GiphyDataDTO.GiphyImagesDTO.GiphyImageMetadataDTO {
    func toDomain() -> GiphyImageMetadata {
        GiphyImageMetadata(height: height, width: width, url: url)
    }
}
