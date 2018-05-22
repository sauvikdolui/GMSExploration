//
//  RouteDrawingVC.swift
//  ProSkoolLocaitonTest
//
//  Created by Sauvik Dolui on 22/05/18.
//  Copyright © 2018 Innofied Solution Pvt. Ltd. All rights reserved.
//

import UIKit
import GoogleMaps
import GEOSwift
import MapKit

// https://macwright.org/2015/03/23/geojson-second-bite
class RouteDrawingVC: UIViewController {

    @IBOutlet weak var mapView: GMSMapView!
    
    
    var locationManager =  CLLocationManager()
    var currentLocationMarker = GMSMarker()
    var currentLocationCoordinate: CLLocationCoordinate2D?
    var arrayOfPlacedMarkers = [GMSMarker]()
    var safeRoutePolyline: GMSPolygon?

    // // LINESTRING(35 10, 45 45, 15 40, 10 20, 35 10)
    let xCoordinates:[Double] = [35, 45, 15, 10]
    let yCoordinates:[Double] = [10, 45, 40, 20]
    
    lazy var debugCoordinates: [CLLocationCoordinate2D] = {
        var coordinates = [CLLocationCoordinate2D]()
        for i in 0..<xCoordinates.count {
            coordinates.append(CLLocationCoordinate2D(latitude: xCoordinates[i],
                                                      longitude: yCoordinates[i]))
        }
        return coordinates
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = LocationAccuracy.Best.value
        locationManager.delegate = self
        locationManager.distanceFilter = kCLDistanceFilterNone
        mapView.delegate = self
        locationManager.startUpdatingLocation()
        
        //drawRouteOverlayFromCoordinates(coordinates: debugCoordinates)
        //addMarkersAtCoordinates(coordinates: debugCoordinates)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func drawRouteOverlayFromCoordinates(coordinates: [CLLocationCoordinate2D], buffer: Double = 0.0001) {
        
        let lineStringGeometry = Geometry.createFrom(linePathCoordinates: coordinates)
        let bufferedPath = lineStringGeometry?.buffer(width: buffer) as! Polygon
        
        let mutableGMSPolyline = GMSMutablePath(polygon: bufferedPath)
        
        // Removing the old one before creating a new
        if safeRoutePolyline != nil {
            safeRoutePolyline?.map = nil
            safeRoutePolyline = nil
        }
        
        // Polyline drawing
        safeRoutePolyline = GMSPolygon(path: mutableGMSPolyline)
        safeRoutePolyline?.strokeWidth = 1.0
        safeRoutePolyline?.strokeColor = .black
        safeRoutePolyline?.fillColor = UIColor.black.withAlphaComponent(0.2)
        safeRoutePolyline?.map = mapView
    }
    func addMarkersAtCoordinates(coordinates: [CLLocationCoordinate2D]) {
        for coordinate in coordinates {
            let newMarker = GMSMarker(position: coordinate)
            newMarker.isDraggable = true
            newMarker.appearAnimation = .pop
            newMarker.map = self.mapView
        }
    }

}
extension RouteDrawingVC : GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
        
        let newMarker = GMSMarker(position: coordinate)
        newMarker.isDraggable = true
        newMarker.appearAnimation = .pop
        newMarker.map = self.mapView
        arrayOfPlacedMarkers.append(newMarker)
        if arrayOfPlacedMarkers.count > 1 {
            drawRouteOverlayFromCoordinates(coordinates: arrayOfPlacedMarkers.map {$0.position})
        }
    }
    
    // MARK: DRAGGING A MARKER
    func mapView(_ mapView: GMSMapView, didBeginDragging marker: GMSMarker) {

    }
    func mapView(_ mapView: GMSMapView, didDrag marker: GMSMarker) {
        
    }
    func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker) {

    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        return true
    }
    
}

extension RouteDrawingVC: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locaiton = locations.last else {
            return
        }
        
        if let _  = currentLocationCoordinate {
            
        } else {
            currentLocationCoordinate = locaiton.coordinate
            let camera = GMSCameraPosition.camera(withLatitude: currentLocationCoordinate!.latitude,
                                                  longitude: currentLocationCoordinate!.longitude, zoom: 14)
            mapView.camera = camera
        }
        
        currentLocationMarker.appearAnimation = .pop
        currentLocationMarker.position = locaiton.coordinate
        currentLocationMarker.map = self.mapView
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


