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



class SafeZoneDrawingVC: UIViewController {

    
    var locationManager =  CLLocationManager()
    var currentLocationCoordinate: CLLocationCoordinate2D?
    
    var currentLocationMarker = GMSMarker()
    var arrayOfPlacedMarkers = [GMSMarker]()

    var fenceCircle: GMSCircle?
    var safeAreaPolygon: GMSPolygon?

    var isDraggingGoingOn: Bool = false

    
    
    let distanceFilterOptions = [
        kCLDistanceFilterNone,
        5.0, 10.0,
        20.0, 30.0,
        50.0, 75.0,
        100.0, 200.0,
        500.0, 1000.0
    ]
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var accuracyLabel: UILabel!
    @IBOutlet weak var distanceFilterLabel: UILabel!
    @IBOutlet weak var radiusLabel: UILabel!
    @IBOutlet weak var slider: UISlider!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Location Manager Set ups
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = LocationAccuracy.Best.value
        locationManager.delegate = self
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.startUpdatingLocation()
        
        // Map view
        mapView.delegate = self

        // Updating the location accuracy label
        accuracyLabel.text = LocationAccuracy.Best.displayString
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
    
   func drawOverlayCoveringMarkers(markers: [CLLocationCoordinate2D]) {
    
        guard markers.count > 2 else {
            print("Can't draw safe zone with less than 3 markers")
            return
        }
    
        // Create a rectangular path
        let rect = GMSMutablePath()
        let oldPositions = markers
        
        // Creates a clock wise sequence of an array of CLLocaitonCoordinate2D from
        // an unordered sequence of coordinates
        let newPosition = PolygonHelper.getClockWiseSequenceFromCoordinateArray(cordinates: oldPositions)
        
        // Clean up
        safeAreaPolygon?.map = nil
        safeAreaPolygon = nil
        
        // Create the final path
        for coordinate in newPosition {
            rect.add(coordinate)
        }
        // Create and render the polygon
        safeAreaPolygon = GMSPolygon(path: rect)
        safeAreaPolygon?.strokeWidth = 1.0
        safeAreaPolygon?.strokeColor = .black
        safeAreaPolygon?.fillColor = UIColor.black.withAlphaComponent(0.2)
        safeAreaPolygon?.map = mapView
    
        // DATA TO SEND TO SERVER ON SAVE OF THIS POLYGON PATH
        // 1. ENCODED PATH
        // 2. AN ARRAY OF COORDINATES WHICH ARE FORMING THE SAFE AREA OR ZONE
        //let encodedPath = safeAreaPolygon?.path?.encodedPath
        //let coordinates = safeAreaPolygon?.path?.coordinates
    
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

extension SafeZoneDrawingVC : GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
        if isDraggingGoingOn { return }
        
        // Create a new marker
        let newMarker = GMSMarker(position: coordinate)
        newMarker.isDraggable = true
        newMarker.appearAnimation = .pop
        newMarker.map = self.mapView
        arrayOfPlacedMarkers.append(newMarker)
        
        // Draw the safe area/zone
        drawOverlayCoveringMarkers(markers: arrayOfPlacedMarkers.map {$0.position})
    }
    
    // MARK: DRAGGING A MARKER
    func mapView(_ mapView: GMSMapView, didBeginDragging marker: GMSMarker) {
        isDraggingGoingOn = true
        if marker == currentLocationMarker { return }
    }
    func mapView(_ mapView: GMSMapView, didDrag marker: GMSMarker) {
        if marker == currentLocationMarker { return }
        drawOverlayCoveringMarkers(markers: arrayOfPlacedMarkers.map {$0.position})
    }
    func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker) {
        isDraggingGoingOn = false
        if marker == currentLocationMarker { return }
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        return true
    }

}

extension SafeZoneDrawingVC: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locaiton = locations.last else {
            return
        }

        if let _  = currentLocationCoordinate {
            // Received location updated earlier
        } else {
            // Received location update for the first time, let create the camera and position
            // map on currrent location
            currentLocationCoordinate = locaiton.coordinate
            let camera = GMSCameraPosition.camera(withLatitude: currentLocationCoordinate!.latitude,
                                                  longitude: currentLocationCoordinate!.longitude, zoom: 14)
            mapView.camera = camera
        }
        
        if let _ = fenceCircle {
            // fence cirle (blue circle around current location of device) already created
        } else {
            // Fence cirle was not found, lets create one
            fenceCircle = GMSCircle(position: locaiton.coordinate, radius: Double(slider.value))
            fenceCircle?.strokeWidth = 1.0
            fenceCircle?.strokeColor = UIColor.blue
            fenceCircle?.fillColor = UIColor.blue.withAlphaComponent(0.20)
            fenceCircle?.map = mapView
        }
        // Positioning the current location showing cirle
        fenceCircle?.position = locaiton.coordinate
        
        // Updating current location marker
        currentLocationMarker.appearAnimation = .pop
        currentLocationMarker.position = locaiton.coordinate
        currentLocationMarker.map = self.mapView
    }
}

