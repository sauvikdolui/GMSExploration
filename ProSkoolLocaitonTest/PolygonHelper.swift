//
//  PolygonHelper.swift
//  ProSkoolLocaitonTest
//
//  Created by Sauvik Dolui on 12/04/18.
//  Copyright © 2018 Innofied Solution Pvt. Ltd. All rights reserved.
//

import Foundation
import MapKit
import GoogleMaps

class PolygonHelper {
    
    class func getClockWiseSequenceFromCoordinateArray(cordinates: [CLLocationCoordinate2D]) ->  [CLLocationCoordinate2D] {
        
        let xCoordinates = cordinates.reduce(0.0, {
            return $0 + $1.longitude
        })
        let yCoordinates = cordinates.reduce(0.0, {
            return $0 + $1.latitude
        })
        let meanCoordinate = CLLocationCoordinate2D(latitude: yCoordinates/Double(cordinates.count),
                                                    longitude: xCoordinates/Double(cordinates.count))
        
        let coordinatePositions = cordinates.map {
            CLLocationCoordinatePositionInfo(coordinate: $0,
                                             meanCoordinate:meanCoordinate)
            
        }
        return  coordinatePositions.sorted(by: {
            return $0.angle360Measure < $1.angle360Measure
            
        }).map { $0.coordinate }
    }
}

struct CLLocationCoordinatePositionInfo {
    let coordinate: CLLocationCoordinate2D
    let angle360Measure: Double
    let distanceFromOrigin: Double
    let meanCoordinate: CLLocationCoordinate2D
    
    init(coordinate: CLLocationCoordinate2D, meanCoordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        self.meanCoordinate = meanCoordinate
        
        angle360Measure = CLLocationCoordinatePositionInfo.getAngleFromCoordinate(coordinate: self.coordinate,
                                                                                  mean: meanCoordinate)
        distanceFromOrigin = CLLocationCoordinatePositionInfo.getDistanceFromMean(mean: meanCoordinate,
                                                                                  coordinate: self.coordinate)

    }
    
    static func getAngleFromCoordinate(coordinate: CLLocationCoordinate2D, mean: CLLocationCoordinate2D) -> Double {
        
        let angle = atan2((coordinate.latitude - mean.latitude), (coordinate.longitude - mean.longitude))
        let angleInDegree = angle * (180.0 / .pi)
        
        switch coordinate.getCoordinatePosition(coordinate: coordinate, mean: mean) {
        case .first:
            return 90.0 - angleInDegree
        case .second:
            return 90.0 - angleInDegree
        case .third:
            return 360.0 + angleInDegree
        case .fourth:
            return 270.0 + (180.0 - angleInDegree)
            
        }
    }
    static func getDistanceFromMean(mean: CLLocationCoordinate2D, coordinate: CLLocationCoordinate2D) -> Double {
        
        let origin = CLLocation(latitude: mean.latitude, longitude: mean.longitude)
        let locationPoint = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return locationPoint.distance(from: origin)
    }
}


enum CoordinatePostion: Int {
    case first, second, third, fourth
}
extension CLLocationCoordinate2D {
    func  getCoordinatePosition(coordinate:CLLocationCoordinate2D, mean: CLLocationCoordinate2D) -> CoordinatePostion  {
        switch self {
        case let coordinate where coordinate.longitude >= mean.longitude && coordinate.latitude >= mean.latitude:
            return .first
        case let coordinate where coordinate.longitude >= mean.longitude && coordinate.latitude <  mean.latitude:
            return .second
        case let coordinate where coordinate.longitude < mean.longitude && coordinate.latitude <  mean.latitude:
            return .third
        case let coordinate where coordinate.longitude < mean.longitude && coordinate.latitude >=  mean.latitude:
            return .fourth
        default:
            return .first
        }
    }
}
