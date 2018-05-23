//
//  ViewController.swift
//  ProSkoolLocaitonTest
//
//  Created by Sauvik Dolui on 30/03/18.
//  Copyright © 2018 Innofied Solution Pvt. Ltd. All rights reserved.
//

import UIKit
import MapKit
import GoogleMaps
import GEOSwift

enum LocationAccuracy: String {
    case BestForNavigation,
    Best,
    NearestTenMeters,
    HundredMeters,
    Kilometer,
    ThreeKilometers

    var value: Double {
        switch self {
        case .BestForNavigation:
            return kCLLocationAccuracyBestForNavigation
        case .Best:
            return kCLLocationAccuracyBest
        case .NearestTenMeters:
            return kCLLocationAccuracyNearestTenMeters
        case .HundredMeters:
            return kCLLocationAccuracyHundredMeters
        case .Kilometer:
            return kCLLocationAccuracyKilometer
        case .ThreeKilometers:
           return kCLLocationAccuracyThreeKilometers
        }
    }
    var displayString: String {
        return self.rawValue
    }
    
    static var allOptions:[LocationAccuracy] { return
        [
            LocationAccuracy.BestForNavigation,
            LocationAccuracy.Best,
            LocationAccuracy.NearestTenMeters,
            LocationAccuracy.HundredMeters,
            LocationAccuracy.Kilometer,
            LocationAccuracy.ThreeKilometers
        ]
    }
}



class ViewController: UIViewController {

    
    var locationManager =  CLLocationManager()
    var currentLocationMarker = GMSMarker()
    var currentLocationCoordinate: CLLocationCoordinate2D?
    var fenceCircle: GMSCircle?
    var arrayOfPlacedMarkers = [GMSMarker]()
    var safeAreaPolygon: GMSPolygon?
    var safeRoutePolyline: GMSPolyline?
    var unionPolygon: GMSPolygon?

    var safeRoutePolylineRef1: GMSPolyline?
    var safeRoutePolylineRef2: GMSPolyline?
    var isDraggingGoingOn: Bool = false
    
    var safeRoutePolygons = [GMSPolygon]()
    
    var halfAngleMarker:GMSMarker?
    
    
    let distanceFilterOptions = [kCLDistanceFilterNone, 5.0, 10.0, 20.0, 30.0, 50.0, 75.0, 100.0, 200.0, 500.0, 1000.0 ]
    
    var polygonPointsArray:[[CLLocationCoordinate2D]] = [[CLLocationCoordinate2D]]()
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var accuracyLabel: UILabel!
    @IBOutlet weak var distanceFilterLabel: UILabel!
    @IBOutlet weak var radiusLabel: UILabel!
    @IBOutlet weak var slider: UISlider!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = LocationAccuracy.Best.value
        accuracyLabel.text = LocationAccuracy.Best.displayString
        locationManager.delegate = self
        locationManager.distanceFilter = kCLDistanceFilterNone
        mapView.delegate = self
        
        locationManager.startUpdatingLocation()
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func accuracyButtonTapped(_ sender: UIButton) {
        self.presentLocationAccuracyOptions()
    }
    @IBAction func distanceFilerButtonTapped(_ sender: UIButton) {
        self.presentDistaceFilterOptions()
    }
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        guard let circle = fenceCircle else { return }
        let intValue = Int(sender.value)
        radiusLabel.text = "Radius - \(intValue)m"
        circle.radius = Double(sender.value)
    }
    
    func drawOverlayCoveringMarkers(markers: [CLLocationCoordinate2D]) -> GMSPolygon {
        
        // Create a rectangular path
        let rect = GMSMutablePath()
        let oldPositions = markers
        //let newPosition = PolygonHelper.getClockWiseSequenceFromCoordinateArray(cordinates: oldPositions)
        for coordinate in oldPositions {
            rect.add(coordinate)
        }
        
        let polygon = GMSPolygon(path: rect)
        polygon.strokeWidth = 1.0
        polygon.strokeColor = .black
        polygon.fillColor = UIColor.black.withAlphaComponent(0.2)
        polygon.map = mapView
        
        return polygon
        
    }
    func drawPolyline(path: GMSPath, color: UIColor) -> GMSPolyline {
        let line = GMSPolyline(path: path)
        line.strokeColor = color
        line.strokeWidth = 2.0
        return line
    }

    
    private func presentLocationAccuracyOptions() {
        
        let alertController = UIAlertController(title: "Select One", message: nil, preferredStyle: .actionSheet)
        
        for locationAccuracy in LocationAccuracy.allOptions {
            let alertAction = UIAlertAction(title: locationAccuracy.displayString,
                                            style: .default,
                                            handler: { (action) in
                        guard let title = action.title,
                        let accuracy = LocationAccuracy(rawValue: title) else {
                            return
                        }
                        self.locationManager.desiredAccuracy = accuracy.value
                        self.accuracyLabel.text = accuracy.displayString
            })
            alertController.addAction(alertAction)
        }
        
        let cancelOption = UIAlertAction(title: "Cancel", style: .destructive) { (action) in
            //...
        }
        alertController.addAction(cancelOption)
        // Add Cancel Option
        self.present(alertController, animated: true) {
            //...
        }
    }
    private func presentDistaceFilterOptions() {
        let alertController = UIAlertController(title: "Select Distance Filter", message: nil, preferredStyle: .actionSheet)
        
        for locationAccuracy in distanceFilterOptions {
            
            let title = locationAccuracy == kCLDistanceFilterNone ? "FilterNone" : "\(locationAccuracy)"

            let alertAction = UIAlertAction(title: title,
                                            style: .default,
                                            handler: { (action) in
                                                if let title = action.title {
                                                    print(title)
                                                    switch title {
                                                    case "Cancel":
                                                        ()
                                                    case "FilterNone":
                                                        self.locationManager.distanceFilter = kCLDistanceFilterNone
                                                        self.distanceFilterLabel.text = title
                                                        
                                                    default:
                                                        
                                                        if let filter = Double(title) {
                                                            self.locationManager.distanceFilter = filter
                                                            self.distanceFilterLabel.text = title
                                                        } else {
                                                             print("filter value not created")
                                                        }
                                                    }
                                                } else {
                                                    print("Location title not found")
                                                }
                                                
            })
            alertController.addAction(alertAction)
        }
        
        let cancelOption = UIAlertAction(title: "Cancel", style: .destructive) { (action) in
            //...
        }
        alertController.addAction(cancelOption)
        // Add Cancel Option
        self.present(alertController, animated: true) {
            //...
        }
    }
}

extension ViewController : GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
        if isDraggingGoingOn { return }
        
        // Create a new marker
        let newMarker = GMSMarker(position: coordinate)
        newMarker.isDraggable = true
        newMarker.appearAnimation = .pop
        newMarker.map = self.mapView
        arrayOfPlacedMarkers.append(newMarker)
        
        drawSafeRouteGoingThroughMarkers(markers: arrayOfPlacedMarkers)

        
        
    }
    func drawSafeRouteGoingThroughMarkers(markers: [GMSMarker])  {
        if arrayOfPlacedMarkers.count > 1 {
            
            unionPolygon?.map = nil
            unionPolygon = nil
            for i in 0..<arrayOfPlacedMarkers.count - 1 {
                let points = PolygonHelper.getCoveringPointsFor(A: arrayOfPlacedMarkers[i].position,
                                                                B: arrayOfPlacedMarkers[i + 1].position)
                polygonPointsArray.append(points)
            }
            guard var finalPolygon = Geometry.createPolygonFrom(polygonCoordinates: polygonPointsArray.first!) else {
                return
            }
            // Incremental union
            for i in 1..<polygonPointsArray.count {
                let thisPolygon =  Geometry.createPolygonFrom(polygonCoordinates: polygonPointsArray[i])
                finalPolygon = finalPolygon.union(thisPolygon!) as! Polygon
            }
            
            let pathOfFinalPolygon = GMSMutablePath(polygon: finalPolygon)
            unionPolygon = GMSPolygon(path: pathOfFinalPolygon)
            unionPolygon?.strokeWidth = 1.0
            unionPolygon?.strokeColor = .black
            unionPolygon?.fillColor = UIColor.green.withAlphaComponent(0.2)
            unionPolygon?.map = mapView
        }
    }
    func drawSafeZoneCoveringPoints(arrayOfPlacedMarkers: [GMSMarker]) {
        if let safeRoutePolyline = self.safeRoutePolyline {
            safeRoutePolyline.map = nil
        }
        let mutablePath = GMSMutablePath()
        mutablePath.add(arrayOfPlacedMarkers[0].position)
        mutablePath.add(arrayOfPlacedMarkers[1].position)
        mutablePath.add(arrayOfPlacedMarkers[2].position)
        
        safeRoutePolyline = GMSPolyline(path: mutablePath)
        let styleSpan  = GMSStrokeStyle.gradient(from: UIColor.green.withAlphaComponent(0.3),
                                                 to: UIColor.red.withAlphaComponent(0.3))
        safeRoutePolyline?.strokeColor = UIColor.black.withAlphaComponent(0.3)
        safeRoutePolyline?.spans = [GMSStyleSpan.init(style: styleSpan)]
        safeRoutePolyline?.strokeWidth = 50.0
        safeRoutePolyline?.map = self.mapView
    }
    
    // MARK: DRAGGING A MARKER
    func mapView(_ mapView: GMSMapView, didBeginDragging marker: GMSMarker) {
        isDraggingGoingOn = true
        if marker == currentLocationMarker { return }
    }
    func mapView(_ mapView: GMSMapView, didDrag marker: GMSMarker) {
        if marker == currentLocationMarker { return }
        
        //drawOverlayCoveringMarkers(markers: arrayOfPlacedMarkers)
        //drawSafeZoneCoveringPoints(arrayOfPlacedMarkers: arrayOfPlacedMarkers)
        //drawSafeRouteGoingThroughMarkers(markers: arrayOfPlacedMarkers)
        
        
    }
    func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker) {
        isDraggingGoingOn = false
        if marker == currentLocationMarker { return }
        drawSafeRouteGoingThroughMarkers(markers: arrayOfPlacedMarkers)
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        //print(marker.title)
        return true
    }

}

extension ViewController: CLLocationManagerDelegate {
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
        
        if let _ = fenceCircle {
            
        } else {
            fenceCircle = GMSCircle(position: locaiton.coordinate, radius: Double(slider.value))
            fenceCircle?.strokeWidth = 1.0
            fenceCircle?.strokeColor = UIColor.blue
            fenceCircle?.fillColor = UIColor.blue.withAlphaComponent(0.20)
            fenceCircle?.map = mapView
        }
        fenceCircle?.position = locaiton.coordinate
        currentLocationMarker.appearAnimation = .pop
        currentLocationMarker.position = locaiton.coordinate
        currentLocationMarker.map = self.mapView
    }
}

