//
//  SaveViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/12/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Alamofire
import ObjectMapper
import Async
import SwiftyUserDefaults

class SaveViewModel {
    
    let text = MutableProperty<String>("")
    let isPrivate = MutableProperty<Bool>(false)
    let isReady = MutableProperty<Bool>(false)
    let isInitialized = MutableProperty<Bool>(false)
    let locationLoading = MutableProperty<Bool>(false)
    let postFacebook: MutableProperty<Bool>
    let postTwitter: MutableProperty<Bool>
    let postInstagram: MutableProperty<Bool>
    let isOnline: MutableProperty<Bool>
    let placeID = MutableProperty<String?>(nil)
    
    var optograph: Optograph!
    
    init(placeholderSignal: Signal<UIImage, NoError>) {
        
        postFacebook = MutableProperty(Defaults[.SessionShareToggledFacebook])
        postTwitter = MutableProperty(Defaults[.SessionShareToggledTwitter])
        postInstagram = MutableProperty(Defaults[.SessionShareToggledInstagram])
        
        isOnline = MutableProperty(Reachability.connectedToNetwork())
        
        postFacebook.producer.delayLatestUntil(isInitialized.producer).startWithNext { [weak self] toggled in
            Defaults[.SessionShareToggledFacebook] = toggled
            self?.optograph.postFacebook = toggled
        }
        
        postTwitter.producer.delayLatestUntil(isInitialized.producer).startWithNext { [weak self] toggled in
            Defaults[.SessionShareToggledTwitter] = toggled
            self?.optograph.postTwitter = toggled
        }
        
        postInstagram.producer.delayLatestUntil(isInitialized.producer).startWithNext { [weak self] toggled in
            Defaults[.SessionShareToggledInstagram] = toggled
            self?.optograph.postInstagram = toggled
        }
        
        isPrivate.producer.delayLatestUntil(isInitialized.producer).startWithNext { [weak self] isPrivate in
            self?.optograph.isPrivate = isPrivate
        }
        
        text.producer.delayLatestUntil(isInitialized.producer).startWithNext { [weak self] text in
            self?.optograph.text = text
        }
        
        if isOnline.value {
            ApiService<Optograph>.post("optographs", parameters: ["stitcher_version": StitcherVersion])
                .map { (var optograph) in
                    optograph.isPublished = false
                    optograph.isStitched = false
                    optograph.person.ID = Defaults[.SessionPersonID] ?? Person.guestID
                    return optograph
                }
                .on(next: { [weak self] optograph in
                    self?.optograph = optograph
                })
                .zipWith(placeholderSignal.mapError({ _ in ApiError.Nil }))
                .flatMap(.Latest) { (optograph, image) in
                    return ApiService<EmptyResponse>.upload("optographs/\(optograph.ID)/upload-asset", multipartFormData: { form in
                        form.appendBodyPart(data: "placeholder".dataUsingEncoding(NSUTF8StringEncoding)!, name: "key")
                        form.appendBodyPart(data: UIImageJPEGRepresentation(image, 0.7)!, name: "asset", fileName: "placeholder.jpg", mimeType: "image/jpeg")
                    })
                }
                .on(failed: { [weak self] _ in
                    self?.isOnline.value = false
                    self?.isInitialized.value = true
                })
                .startWithCompleted { [weak self] in
                    self?.isInitialized.value = true
                }
        
            placeID.producer
                .delayLatestUntil(isInitialized.producer)
                .on(next: { [weak self] val in
                    if val == nil {
                        self?.optograph.location = nil
                    }
                    })
                .ignoreNil()
                .on(next: { [weak self] _ in
                    self?.locationLoading.value = true
                    })
                .mapError { _ in ApiError.Nil }
                .flatMap(.Latest) { ApiService<GeocodeDetails>.get("locations/geocode-details/\($0)") }
                .on(failed: { [weak self] _ in
                    let coords = LocationService.lastLocation()!
                    var location = Location.newInstance()
                    location.latitude = coords.latitude
                    location.longitude = coords.longitude
                    self?.optograph.location = location
                })
                .startWithNext { [weak self] geocodeDetails in
                    self?.locationLoading.value = false
                    let coords = LocationService.lastLocation()!
                    var location = Location.newInstance()
                    location.latitude = coords.latitude
                    location.longitude = coords.longitude
                    location.text = geocodeDetails.name
                    location.country = geocodeDetails.country
                    location.countryShort = geocodeDetails.countryShort
                    location.place = geocodeDetails.place
                    location.region = geocodeDetails.region
                    self?.optograph.location = location
                }
        } else {
            optograph = Optograph.newInstance()
            isInitialized.value = true
            
            placeID.producer.startWithNext { [weak self] geocodeDetails in
                let coords = LocationService.lastLocation()!
                var location = Location.newInstance()
                location.latitude = coords.latitude
                location.longitude = coords.longitude
                self?.optograph.location = location
            }
        }
        
        isReady <~ isInitialized.producer
            .combineLatestWith(locationLoading.producer.map(negate)).map(and)
    }
    
    func submit(shouldBePublished: Bool) -> SignalProducer<Void, NoError> {
        
        optograph.shouldBePublished = shouldBePublished
        
        try! optograph.insertOrUpdate()
        try! optograph.location?.insertOrUpdate()
        
        if isOnline.value {
            var parameters: [String: AnyObject] = [
                "text": optograph.text,
                "is_private": optograph.isPrivate,
                "post_facebook": optograph.postFacebook,
                "post_twitter": optograph.postTwitter,
                "direction_phi": optograph.directionPhi,
                "direction_theta": optograph.directionTheta,
            ]
            if let location = optograph.location {
                print(location)
                parameters["location"] = location.toJSON()
            }
            
            return ApiService<EmptyResponse>.put("optographs/\(optograph.ID)", parameters: parameters)
                .ignoreError()
                .map { _ in () }
        } else {
            return SignalProducer(value: ())
        }
    }
}

private struct GeocodeDetails: Mappable {
    var name = ""
    var country = ""
    var countryShort = ""
    var place = ""
    var region = ""
    var POI = false
    
    init() {}
    
    init?(_ map: Map) {}
    
    mutating func mapping(map: Map) {
        name            <- map["name"]
        country         <- map["country"]
        countryShort    <- map["country_short"]
        place           <- map["place"]
        region          <- map["region"]
        POI             <- map["poi"]
    }
}