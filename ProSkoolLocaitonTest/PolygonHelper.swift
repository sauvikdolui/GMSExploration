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
    class func getAngleABOFromPoints(A : CLLocationCoordinate2D, B: CLLocationCoordinate2D, C: CLLocationCoordinate2D) -> Double {
        
        var m1 = 0.0
        if A.longitude - B.longitude == 0 {
            m1 = tan(Double.pi / 2)
        } else {
            m1 = (A.latitude - B.latitude) / (A.longitude - B.longitude)
        }
        var m2 = 0.0
        if B.longitude - C.longitude == 0 {
            m2 = tan(Double.pi / 2)
        } else {
            m2 = (B.latitude - C.latitude) / (B.longitude - C.longitude)
        }
        
        
        
        let value1 = (m2 - m1) / (1 + m1 * m2)
        
        let anglePositiveVe = atan(value1)
        let angleNegativeVe = atan(-value1)
        
        if fabs(anglePositiveVe) < fabs(angleNegativeVe) {
            return fabs(anglePositiveVe) * (180 / Double.pi)
        } else {
            return fabs(angleNegativeVe) * (180 / Double.pi)
        }
    }
    static func getPointOnHalfAngle(A : CLLocationCoordinate2D, B: CLLocationCoordinate2D, C: CLLocationCoordinate2D, distance: Double ) -> CLLocationCoordinate2D{

        let angle = PolygonHelper.getAngleABOFromPoints(A: A, B: B, C: C) / 2.0
        let dX =  distance * cos(angle * (Double.pi / 180.0))
        let dY =  distance * sin(angle * (Double.pi / 180.0))
        return CLLocationCoordinate2D(latitude: B.latitude + dY, longitude: B.longitude + dX)
        
    }
    static func getCoveringPointsFor(A: CLLocationCoordinate2D, B: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
        
        let distance = 0.0001
        
        if (A.longitude - B.longitude) == 0 {
            // Perpendicular to Y axis
            let ALeft = CLLocationCoordinate2D(latitude: A.latitude, longitude: A.longitude - distance)
            let ARight = CLLocationCoordinate2D(latitude: A.latitude, longitude: A.longitude + distance)
            
            let BLeft = CLLocationCoordinate2D(latitude: B.latitude, longitude: B.longitude - distance)
            let BRight = CLLocationCoordinate2D(latitude: B.latitude, longitude: B.longitude + distance)
            
            return [ALeft, ARight, BLeft, BRight ]
        } else  {
            let m = (A.latitude - B.latitude) / (A.longitude - B.longitude)
            
            if  m > 0 {
                // Making > 0 && < 90 angle
                let angle = 90.0 - atan(m) * (180.0 / Double.pi)
                print("angle =\(angle)")
                let dx = distance * cos(angle * (Double.pi / 180.0))
                let dy = distance * sin(angle * (Double.pi / 180.0))
                let ALeft = CLLocationCoordinate2D(latitude: A.latitude + dy, longitude: A.longitude - dx)
                let ARight = CLLocationCoordinate2D(latitude: A.latitude - dy, longitude: A.longitude + dx)
                
                let BLeft = CLLocationCoordinate2D(latitude: B.latitude + dy, longitude: B.longitude - dx)
                let BRight = CLLocationCoordinate2D(latitude: B.latitude - dy, longitude: B.longitude + dx)
                
                return [ALeft, ARight, BRight, BLeft]
            } else {
                // Making > 90 angle
                let angle = 90 + atan(m) * (180.0 / Double.pi)
                let dx = distance * cos(angle * (Double.pi / 180.0))
                let dy = distance * sin(angle * (Double.pi / 180.0))
                
                let ALeft = CLLocationCoordinate2D(latitude: A.latitude - dy, longitude: A.longitude - dx)
                let ARight = CLLocationCoordinate2D(latitude: A.latitude  + dy, longitude: A.longitude + dx)
                
                let BLeft = CLLocationCoordinate2D(latitude: B.latitude - dy, longitude: B.longitude - dx)
                let BRight = CLLocationCoordinate2D(latitude: B.latitude + dy, longitude: B.longitude + dx)
                
                return [ALeft, ARight, BRight, BLeft]
            }
        }
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
