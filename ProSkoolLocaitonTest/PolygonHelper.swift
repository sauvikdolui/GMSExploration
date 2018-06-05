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
import GEOSwift

extension CLLocationCoordinate2D: Comparable {
    public static func < (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude < rhs.latitude && lhs.longitude < rhs.longitude
    }
    
    public static func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
extension GMSMutablePath {
    convenience public init(polygon: Polygon) {
        self.init()
        for location in polygon.exteriorRing.points{
            add(CLLocationCoordinate2DFromCoordinate(location))
        }
    }
}
extension GMSPath {
    var coordinates: [CLLocationCoordinate2D] {
        var coordinates = [CLLocationCoordinate2D]()
        for i in 0..<count() {
            coordinates.append(coordinate(at: i))
        }
        return coordinates
    }
    public convenience init(linearRing: LinearRing) {
        let mutablePath = GMSMutablePath()
        for i in 0..<linearRing.points.count {
            let point = linearRing.points[i]
            mutablePath.add(CLLocationCoordinate2D(latitude: point.y, longitude: point.x))
        }
        self.init(path: mutablePath)
    }
}
class PolygonHelper {
    
    /// Creates a clock-wise sequence from an array of CLLocationCoordinate2D
    ///
    /// - Parameter cordinates: list of randomly choosen coordinates
    /// - Returns: a new array where list of coordinates are sorted accodring to the angle
    ///            in clock wise direction, they are making with mean point(center point)
    /// - Note: For algo refer to [This Question](https://stackoverflow.com/questions/6671183/calculate-the-center-point-of-multiple-latitude-longitude-coordinate-pairs)
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
    
    
    /// Creates a rectangle with four points where axis of the rectange is parallel to the straight line AB.
    /// There are two offset added points for each of A and B. The final rectangle always coveres AB
    /// - Parameters:
    ///   - A: First point of the straight line
    ///   - B: Second point of the straight line
    /// - Returns: The four points in a sequence of the rectangle
    static func getCoveringPointsFor(A: CLLocationCoordinate2D, B: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
        
        let distance = 0.0001
        
        if (A.longitude - B.longitude) == 0 && A != B {
            // Both residing on a line parallel to X Axis
            var leftOfAB = A.latitude <= B.latitude ? A : B
            var rightOfAB = A.latitude > B.latitude ? A : B
            
            leftOfAB = CLLocationCoordinate2D(latitude: leftOfAB.latitude - distance, longitude: leftOfAB.longitude)
            rightOfAB = CLLocationCoordinate2D(latitude: rightOfAB.latitude + distance, longitude: rightOfAB.longitude)
            
            
            let ATop = CLLocationCoordinate2D(latitude: leftOfAB.latitude, longitude: leftOfAB.longitude + distance)
            let ABottom = CLLocationCoordinate2D(latitude: leftOfAB.latitude, longitude: leftOfAB.longitude - distance)
            
            let BTop = CLLocationCoordinate2D(latitude: rightOfAB.latitude, longitude: rightOfAB.longitude + distance)
            let BBottom = CLLocationCoordinate2D(latitude: rightOfAB.latitude, longitude: rightOfAB.longitude - distance)
            
            return [ATop, ABottom, BBottom, BTop ]
        } else if (A.latitude - B.latitude) == 0 {
            // Both residing on a line parallel to Y Axis
            var bottomOfAB = A.longitude <= B.longitude ? A : B
            var topOfAB = A.longitude > B.longitude ? A : B
            
            bottomOfAB = CLLocationCoordinate2D(latitude: bottomOfAB.latitude,
                                                longitude: bottomOfAB.longitude - distance)
            topOfAB = CLLocationCoordinate2D(latitude: topOfAB.latitude,
                                             longitude: topOfAB.longitude + distance)
            
            let topLeft = CLLocationCoordinate2D(latitude: topOfAB.latitude - distance,
                                                 longitude: topOfAB.longitude)
            let topRight = CLLocationCoordinate2D(latitude: topOfAB.latitude + distance,
                                                  longitude: topOfAB.longitude)
            
            let bottomLeft = CLLocationCoordinate2D(latitude: bottomOfAB.latitude - distance,
                                                    longitude: bottomOfAB.longitude)
            let bottomRight = CLLocationCoordinate2D(latitude: bottomOfAB.latitude + distance,
                                                     longitude: bottomOfAB.longitude)
            
            return [topLeft, topRight, bottomRight, bottomLeft]
        } else  {
            let m = (A.latitude - B.latitude) / (A.longitude - B.longitude)
            
            if  m > 0 {
                // Making > 0 && < 90 angle
                let angle = 90.0 - atan(m) * (180.0 / Double.pi)
                print("angle =\(angle)")
                let dx = distance * cos(angle * (Double.pi / 180.0))
                let dy = distance * sin(angle * (Double.pi / 180.0))
                
                let (updatedA, updatedB) = PolygonHelper.getDistanceAddedPoints(A: A, B: B, distance: distance)
                let ALeft = CLLocationCoordinate2D(latitude: updatedA.latitude + dy, longitude: updatedA.longitude - dx)
                let ARight = CLLocationCoordinate2D(latitude: updatedA.latitude - dy, longitude: updatedA.longitude + dx)
                
                let BLeft = CLLocationCoordinate2D(latitude: updatedB.latitude + dy, longitude: updatedB.longitude - dx)
                let BRight = CLLocationCoordinate2D(latitude: updatedB.latitude - dy, longitude: updatedB.longitude + dx)
                
                return [ALeft, ARight, BRight, BLeft]
            } else {
                // Making > 90 angle
                let angle = 90 + atan(m) * (180.0 / Double.pi)
                let dx = distance * cos(angle * (Double.pi / 180.0))
                let dy = distance * sin(angle * (Double.pi / 180.0))
                
                let (updatedA, updatedB) = PolygonHelper.getDistanceAddedPoints(A: A, B: B, distance: distance)

                let ALeft = CLLocationCoordinate2D(latitude: updatedA.latitude - dy, longitude: updatedA.longitude - dx)
                let ARight = CLLocationCoordinate2D(latitude: updatedA.latitude  + dy, longitude: updatedA.longitude + dx)
                
                let BLeft = CLLocationCoordinate2D(latitude: updatedB.latitude - dy, longitude: updatedB.longitude - dx)
                let BRight = CLLocationCoordinate2D(latitude: updatedB.latitude + dy, longitude: updatedB.longitude + dx)
                
                return [ALeft, ARight, BRight, BLeft]
            }
        }
    }
    
    /// Adds a distance offset on a straight line. If two points are A and B, it will return two points(A',B')
    /// on the extented straight line. Both A' and B' do not resides on AB, but they both on extended AB. Distance of
    /// AA' and BB' are same.
    ///
    /// - Parameters:
    ///   - A: The first point of straight line
    ///   - B: The second point of straight line
    ///   - distance: The offset distance
    /// - Returns: A tuple of two coordinates(A', B')
    static func getDistanceAddedPoints(A: CLLocationCoordinate2D,
                                       B: CLLocationCoordinate2D,
                                       distance: Double) -> (CLLocationCoordinate2D, CLLocationCoordinate2D) {
        
        let m = (A.latitude - B.latitude) / (A.longitude - B.longitude)
        
        if m > 0 {
            // making  > 0 & < 90 angle with +ve X-Axis
            let topPoint = A.longitude > B.longitude ? A : B
            let bottomPoint = A.longitude < B.longitude ? A : B
            
            let angle = 90.0 - atan(m) * (180.0 / Double.pi)
            let dx = distance * cos(angle * (Double.pi / 180.0))
            let dy = distance * sin(angle * (Double.pi / 180.0))

            
            let updatedTop = CLLocationCoordinate2D(latitude: topPoint.latitude + dx,
                                                    longitude: topPoint.longitude + dy)
            let updatedBottom = CLLocationCoordinate2D(latitude: bottomPoint.latitude - dx,
                                                    longitude: bottomPoint.longitude - dy)
            return (updatedTop, updatedBottom)
        } else {
            // making  > 0 & > 90 angle with +ve X-Axis
            
            let topPoint = A.longitude > B.longitude ? A : B
            let bottomPoint = A.longitude < B.longitude ? A : B
            
            let angle = 90 + atan(m) * (180.0 / Double.pi)
            let dx = distance * cos(angle * (Double.pi / 180.0))
            let dy = distance * sin(angle * (Double.pi / 180.0))
            
            let updatedTop = CLLocationCoordinate2D(latitude: topPoint.latitude - dx,
                                                    longitude: topPoint.longitude + dy)
            let updatedBottom = CLLocationCoordinate2D(latitude: bottomPoint.latitude + dx,
                                                       longitude: bottomPoint.longitude - dy)
            return (updatedTop, updatedBottom)
        }
        
    }
    
}

struct CLLocationCoordinatePositionInfo {
    let coordinate: CLLocationCoordinate2D
    let angle360Measure: Double
    let distanceFromOrigin: Double
    let meanCoordinate: CLLocationCoordinate2D
    
    /// A structure of meta data for calculation of a clockwise sequence from an array of coordinates
    ///
    /// - Parameters:
    ///   - coordinate: The point/coordinates for which meta data are to be calculated
    ///   - meanCoordinate: The center point of the all coordinates
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
    func getCoordinatePosition(coordinate:CLLocationCoordinate2D, mean: CLLocationCoordinate2D) -> CoordinatePostion  {
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
extension Geometry {
    class func createFrom(linePathCoordinates: [CLLocationCoordinate2D]) -> Geometry? {
        // Create String from linePathCoordinates
        // Geometry.create("LINESTRING(35 10, 45 45, 15 40, 10 20, 35 10)")
        let coordinatePairs = linePathCoordinates.map { "\($0.latitude) \($0.longitude)" }.joined(separator: ", ")
        let finalString = "LINESTRING(\(coordinatePairs))"
        return Geometry.create(finalString)
    }
    class func createPolygonFrom(polygonCoordinates: [CLLocationCoordinate2D]) -> Polygon? {
        var circularRing:[CLLocationCoordinate2D] = polygonCoordinates
        circularRing.append(polygonCoordinates.first!)
        let coordinateArray = circularRing.map { Coordinate(x: $0.longitude, y: $0.latitude)}
        guard let linerRing = LinearRing(points: coordinateArray) else {
            return nil
        }
        return Polygon(shell: linerRing, holes: nil)
    }
}
