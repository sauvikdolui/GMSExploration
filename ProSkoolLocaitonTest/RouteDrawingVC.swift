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
    
    // Location Manager
    var locationManager =  CLLocationManager()
    
    // Current Location
    var currentLocationMarker = GMSMarker()
    var currentLocationCoordinate: CLLocationCoordinate2D?
    
    // Safe route properties
    var arrayOfPlacedMarkers = [GMSMarker]()
    var isDraggingGoingOn: Bool = false
    var unionPolygon: GMSPolygon?
    var polygonPointsArray:[[CLLocationCoordinate2D]] = [[CLLocationCoordinate2D]]()
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = LocationAccuracy.Best.value
        locationManager.delegate = self
        locationManager.distanceFilter = kCLDistanceFilterNone
        mapView.delegate = self
        locationManager.startUpdatingLocation()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func backButtonTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    /// Draws a safe route covering the markers
    ///
    /// - Parameter markers: An array of markers in a sequence which will be acting as
    ///                      the turning points of the route we are going to draw
    func drawSafeRouteGoingThroughMarkers(markers: [GMSMarker])  {
        
        if arrayOfPlacedMarkers.count > 1 {
            
            // No of markers > 1, at least 2 can draw a route
            
            // Clean up
            unionPolygon?.map = nil
            unionPolygon = nil
            polygonPointsArray = []
            
            
            // Calculating a siglen rectangle( unit of polygon) covering two marker a time
            for i in 0..<arrayOfPlacedMarkers.count - 1 {
                let points = PolygonHelper.getCoveringPointsFor(A: arrayOfPlacedMarkers[i].position,
                                                                B: arrayOfPlacedMarkers[i + 1].position)
                polygonPointsArray.append(points)
            }
            
            // Creating the first Polygon <--- Geometry
            guard var finalPolygon = Geometry.createPolygonFrom(polygonCoordinates: polygonPointsArray.first!) else {
                return
            }
            
            // Incremental union: Union of n - 1 polygons with the help of GeoSwift
            for i in 1..<polygonPointsArray.count {
                let thisPolygon =  Geometry.createPolygonFrom(polygonCoordinates: polygonPointsArray[i])
                finalPolygon = finalPolygon.union(thisPolygon!) as! Polygon
            }
            // Calculation of internal holes

            
            
            // Rendering of polygon on map
            let pathOfFinalPolygon = GMSMutablePath(polygon: finalPolygon)
            unionPolygon = GMSPolygon(path: pathOfFinalPolygon)
            unionPolygon?.holes = finalPolygon.interiorRings.map{ GMSPath(linearRing: $0)}
            unionPolygon?.strokeWidth = 1.0
            unionPolygon?.strokeColor = .black
            unionPolygon?.fillColor = UIColor.green.withAlphaComponent(0.2)
            unionPolygon?.map = mapView
            
            
            // ----------------------------------------
            //        Data to be sent to server
            //  1. The string encoded (https://developers.google.com/maps/documentation/utilities/polylinealgorithm) path of unionPolyline
            //  2. The array of coordinate point in a sequence
            // ----------------------------------------
            
            // 1. The string encoded path
            let stringEncodedPath = unionPolygon?.path?.encodedPath()
            // 2. Array of coordinate points
            let arrayOfBoundingCoordinates = unionPolygon?.path?.coordinates
            
        } else {
            print("ERROR: Can't draw the route polygon less than two marker")
        }
    }

}
extension RouteDrawingVC : GMSMapViewDelegate {
    
    func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
        
        if isDraggingGoingOn { return }
        
        // Create a new marker
        let newMarker = GMSMarker(position: coordinate)
        newMarker.isDraggable = true
        newMarker.appearAnimation = .pop
        newMarker.map = self.mapView
        arrayOfPlacedMarkers.append(newMarker)
        
        // Draw safe routes
        drawSafeRouteGoingThroughMarkers(markers: arrayOfPlacedMarkers)
    }
    
    // MARK: DRAGGING A MARKER
    func mapView(_ mapView: GMSMapView, didBeginDragging marker: GMSMarker) {
        isDraggingGoingOn = true
    }
    func mapView(_ mapView: GMSMapView, didDrag marker: GMSMarker) {
        
    }
    func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker) {
        isDraggingGoingOn = false
        if marker == currentLocationMarker { return }
        drawSafeRouteGoingThroughMarkers(markers: arrayOfPlacedMarkers)
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
            // We received location update earlier
        } else {
            // Received location for the very first time
            currentLocationCoordinate = locaiton.coordinate
            let camera = GMSCameraPosition.camera(withLatitude: currentLocationCoordinate!.latitude,
                                                  longitude: currentLocationCoordinate!.longitude,
                                                  zoom: 14)
            mapView.camera = camera
        }
        currentLocationMarker.appearAnimation = .pop
        currentLocationMarker.position = locaiton.coordinate
        currentLocationMarker.map = self.mapView
    }
}




