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
    var safeRoutePolylineRef1: GMSPolyline?
    var safeRoutePolylineRef2: GMSPolyline?
    var isDraggingGoingOn: Bool = false
    
    
    let distanceFilterOptions = [kCLDistanceFilterNone, 5.0, 10.0, 20.0, 30.0, 50.0, 75.0, 100.0, 200.0, 500.0, 1000.0 ]
    
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
    
    func drawOverlayCoveringMarkers(markers: [GMSMarker]) {
        
        // Create a rectangular path
        let rect = GMSMutablePath()
        let oldPositions = markers.map ({ $0.position })
        let newPosition = PolygonHelper.getClockWiseSequenceFromCoordinateArray(cordinates: oldPositions)
        for coordinate in newPosition {
            rect.add(CLLocationCoordinate2D(latitude: coordinate.latitude, longitude:  coordinate.longitude))
        }
        
        if let oldPolygon = safeAreaPolygon {
            oldPolygon.map = nil
            
        } else {
            
        }
        safeAreaPolygon = GMSPolygon(path: rect)
        safeAreaPolygon?.strokeWidth = 1.0
        safeAreaPolygon?.strokeColor = .black
        safeAreaPolygon?.fillColor = UIColor.black.withAlphaComponent(0.2)
        safeAreaPolygon?.map = mapView
        
    }
    func drawPolyline(path: GMSPath, color: UIColor) -> GMSPolyline {
        let line = GMSPolyline(path: path)
        line.strokeColor = color
        line.strokeWidth = 2.0
        return line
    }
    
    func drawPolyLines(markers: [GMSMarker]) {
        
        let rect = GMSMutablePath()
        
        for coordinate in markers.map ({ $0.position }) {
            rect.add(CLLocationCoordinate2D(latitude: coordinate.latitude, longitude:  coordinate.longitude))
        }
        
        if let line = safeRoutePolyline {
            line.map = nil
            safeRoutePolyline = drawPolyline(path: rect, color: .black)
            safeRoutePolyline?.map = self.mapView
        } else {
            safeRoutePolyline = drawPolyline(path: rect, color: .black)
            safeRoutePolyline?.map = self.mapView
        }
        
        let ref1 = rect.pathOffset(byLatitude: 0.25, longitude: 0.25)
        
        if let line = safeRoutePolylineRef1 {
            line.map = nil
            safeRoutePolylineRef1 = drawPolyline(path: ref1, color: .black)
            safeRoutePolylineRef1?.map = self.mapView
        } else {
            safeRoutePolylineRef1 = drawPolyline(path: ref1, color: .black)
            safeRoutePolylineRef1?.map = self.mapView
        }
        
        let ref2 = rect.pathOffset(byLatitude: -0.25, longitude: -0.25)
        if let line = safeRoutePolylineRef2 {
            line.map = nil
            safeRoutePolylineRef2 = drawPolyline(path: ref2, color: .black)
            safeRoutePolylineRef2?.map = self.mapView
        } else {
            safeRoutePolylineRef2 = drawPolyline(path: ref2, color: .black)
            safeRoutePolylineRef2?.map = self.mapView
        }
        
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
        
        if arrayOfPlacedMarkers.count > 2 {
            drawOverlayCoveringMarkers(markers: arrayOfPlacedMarkers)
            //drawPolyLines(markers: arrayOfPlacedMarkers)
        }
    }
    
    // MARK: DRAGGING A MARKER
    func mapView(_ mapView: GMSMapView, didBeginDragging marker: GMSMarker) {
        isDraggingGoingOn = true
        if marker == currentLocationMarker { return }
    }
    func mapView(_ mapView: GMSMapView, didDrag marker: GMSMarker) {
        if marker == currentLocationMarker { return }
        
        drawOverlayCoveringMarkers(markers: arrayOfPlacedMarkers)
        
        
    }
    func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker) {
        isDraggingGoingOn = false
        if marker == currentLocationMarker { return }
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        print(arrayOfPlacedMarkers.index(of: marker))
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

