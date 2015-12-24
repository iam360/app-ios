//
//  Optograph.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import ObjectMapper
import ReactiveCocoa
import Kingfisher

enum OptographAsset {
    case PreviewImage(NSData)
    case LeftImage(NSData)
    case RightImage(NSData)
}

typealias HashtagStrings = Array<String>

struct Optograph: DeletableModel {
    
    var ID: UUID
    var text: String
    var person: Person
    var createdAt: NSDate
    var deletedAt: NSDate?
    var isStarred: Bool
    var starsCount: Int
    var commentsCount: Int
    var viewsCount: Int
    var location: Location?
    var isPrivate: Bool
    var isStitched: Bool
    var isPublished: Bool
    var stitcherVersion: String
    var shareAlias: String
    var previewAssetID: UUID
    var leftTextureAssetID: UUID
    var rightTextureAssetID: UUID
    var isStaffPick: Bool
    var hashtagString: String
    
    static func newInstance() -> Optograph {
        return Optograph(
            ID: uuid(),
            text: "",
            person: Person.newInstance(),
            createdAt: NSDate(),
            deletedAt: nil,
            isStarred: false,
            starsCount: 0,
            commentsCount: 0,
            viewsCount: 0,
            location: nil,
            isPrivate: false,
            isStitched: false,
            isPublished: false,
            stitcherVersion: "",
            shareAlias: "",
            previewAssetID: "",
            leftTextureAssetID: "",
            rightTextureAssetID: "",
            isStaffPick: false,
            hashtagString: ""
        )
    }
    
    func saveAsset(asset: OptographAsset) {
        switch asset {
        case .LeftImage(let data):
            ImageCache.defaultCache.storeImage(UIImage(data: data)!, forKey: ImageURL(leftTextureAssetID))
        case .RightImage(let data):
            ImageCache.defaultCache.storeImage(UIImage(data: data)!, forKey: ImageURL(rightTextureAssetID))
        case .PreviewImage(let data):
            ImageCache.defaultCache.storeImage(UIImage(data: data)!, forKey: ImageURL(previewAssetID))
            // needs all different sizes
            ImageCache.defaultCache.storeImage(UIImage(data: data)!, forKey: ImageURL(previewAssetID, fullDimension: .Width))
            ImageCache.defaultCache.storeImage(UIImage(data: data)!, forKey: ImageURL(previewAssetID, width: 32, height: 40))
        }
    }
    
    mutating func publish() -> SignalProducer<Optograph, ApiError> {
        assert(!isPublished)
        
        return KingfisherManager.sharedManager.downloader.downloadDataForURL(ImageURL(leftTextureAssetID))
            .combineLatestWith(KingfisherManager.sharedManager.downloader.downloadDataForURL(ImageURL(rightTextureAssetID)))
            .combineLatestWith(KingfisherManager.sharedManager.downloader.downloadDataForURL(ImageURL(previewAssetID)))
            .map { ($0.0, $0.1, $1) }
            .map { (left, right, preview) -> [String: AnyObject] in
                var parameters = Mapper().toJSON(self)
                
                parameters["left_texture_asset"] = left.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
                parameters["right_texture_asset"] = right.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
                parameters["preview_asset"] = preview.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
                
                return parameters
            }
            .mapError { _ in ApiError.Nil }
            .flatMap(.Latest) { ApiService.post("optographs", parameters: $0) }
            .on(completed: {
                self.isPublished = true
                
                try! DatabaseService.defaultConnection.run(
                    OptographTable.filter(OptographSchema.ID ==- self.ID).update(
                        OptographSchema.isPublished <-- self.isPublished
                    )
                )
            })
    }
    
    mutating func delete() -> SignalProducer<EmptyResponse, ApiError> {
        var signalProducer: SignalProducer<EmptyResponse, ApiError>
        if isPublished {
            signalProducer = ApiService<EmptyResponse>.delete("optographs/\(ID)")
        } else {
            signalProducer = SignalProducer { sink, disposable in
                disposable.addDisposable {}
                sink.sendCompleted()
            }
        }
        
        return signalProducer
            .on(completed: {
                self.deletedAt = NSDate()
                try! self.insertOrUpdate()
            })
    }
    
    func report() -> SignalProducer<EmptyResponse, ApiError> {
        return ApiService<EmptyResponse>.post("optographs/\(ID)/report")
    }
}

func ==(lhs: Optograph, rhs: Optograph) -> Bool {
    guard let lhsLocation = lhs.location, rhsLocation = rhs.location else {
        return lhs.location == nil && rhs.location == nil
    }
    
    return lhs.ID == rhs.ID
        && lhs.isStitched == rhs.isStitched
        && lhs.starsCount == rhs.starsCount
        && lhs.isPublished == rhs.isPublished
        && lhs.isStarred == rhs.isStarred
        && lhs.starsCount == rhs.starsCount
        && lhs.person == rhs.person
        && lhsLocation == rhsLocation
}

extension Optograph: Mappable {
    
    init?(_ map: Map){
        self = Optograph.newInstance()
    }
    
    mutating func mapping(map: Map) {
        if map.mappingType == .FromJSON {
            isStitched = true
            isPublished = true
        }
        
        ID                  <- map["id"]
        text                <- map["text"]
        person              <- map["person"]
        createdAt           <- (map["created_at"], NSDateTransform())
        deletedAt           <- (map["deleted_at"], NSDateTransform())
        isStarred           <- map["is_starred"]
        isPrivate           <- map["is_private"]
        stitcherVersion     <- map["stitcher_version"]
        shareAlias          <- map["share_alias"]
        starsCount          <- map["stars_count"]
        commentsCount       <- map["comments_count"]
        viewsCount          <- map["views_count"]
        location            <- map["location"]
        previewAssetID      <- map["preview_asset_id"]
        leftTextureAssetID  <- map["left_texture_asset_id"]
        rightTextureAssetID <- map["right_texture_asset_id"]
        isStaffPick         <- map["is_staff_pick"]
        hashtagString       <- map["hashtag_string"]
    }
    
}

extension Optograph: SQLiteModel {
    
    static func schema() -> ModelSchema {
        return OptographSchema
    }
    
    static func table() -> SQLiteTable {
        return OptographTable
    }
    
    static func fromSQL(row: SQLiteRow) -> Optograph {
        return Optograph(
            ID: row[OptographSchema.ID],
            text: row[OptographSchema.text],
            person: Person.newInstance(),
            createdAt: row[OptographSchema.createdAt],
            deletedAt: row[OptographSchema.deletedAt],
            isStarred: row[OptographSchema.isStarred],
            starsCount: row[OptographSchema.starsCount],
            commentsCount: row[OptographSchema.commentsCount],
            viewsCount: row[OptographSchema.viewsCount],
            location: nil,
            isPrivate: row[OptographSchema.isPrivate],
            isStitched: row[OptographSchema.isStitched],
            isPublished: row[OptographSchema.isPublished],
            stitcherVersion: row[OptographSchema.stitcherVersion],
            shareAlias: row[OptographSchema.shareAlias],
            previewAssetID: row[OptographSchema.previewAssetID],
            leftTextureAssetID: row[OptographSchema.leftTextureAssetID],
            rightTextureAssetID: row[OptographSchema.rightTextureAssetID],
            isStaffPick: row[OptographSchema.isStaffPick],
            hashtagString: row[OptographSchema.hashtagString]
        )
    }
    
    func toSQL() -> [SQLiteSetter] {
        return [
            OptographSchema.ID <-- ID,
            OptographSchema.text <-- text,
            OptographSchema.personID <-- person.ID,
            OptographSchema.createdAt <-- createdAt,
            OptographSchema.deletedAt <-- deletedAt,
            OptographSchema.isStarred <-- isStarred,
            OptographSchema.starsCount <-- starsCount,
            OptographSchema.commentsCount <-- commentsCount,
            OptographSchema.viewsCount <-- viewsCount,
            OptographSchema.locationID <-- location?.ID,
            OptographSchema.isPrivate <-- isPrivate,
            OptographSchema.isStitched <-- isStitched,
            OptographSchema.isPublished <-- isPublished,
            OptographSchema.stitcherVersion <-- stitcherVersion,
            OptographSchema.shareAlias <-- shareAlias,
            OptographSchema.previewAssetID <-- previewAssetID,
            OptographSchema.leftTextureAssetID <-- leftTextureAssetID,
            OptographSchema.rightTextureAssetID <-- rightTextureAssetID,
            OptographSchema.isStaffPick <-- isStaffPick,
            OptographSchema.hashtagString <-- hashtagString,
        ]
    }
    
}
