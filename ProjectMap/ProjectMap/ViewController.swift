//
//  ViewController.swift
//  ProjectMap
//
//  Created by macbook on 30.05.2023.
//

import UIKit
import MapKit
import CoreLocation
import Layoutless
import AVFoundation

class MapViewController: UIViewController {
    
    var steps: [MKRoute.Step] = []
    var stepCounter = 0
    var router: MKRoute?
    var showMapRoute = false
    var navigationStarted = false
    let locationDistance: Double = 500
    
    var speechsynthesizer = AVSpeechSynthesizer()
    private let mapView = MKMapView()
 
    
    lazy var directionLabel: UILabel = {
       let label = UILabel()
        label.text = "Where do you want to go?"
        label.font = .boldSystemFont(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    lazy var textField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter your destination"
        tf.borderStyle = .roundedRect
        return tf
    }()
    
    lazy var getDirectionButton: UIButton = {
       let button = UIButton()
        button.setTitle("Get Direction", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.addTarget(self, action: #selector(getDirectionButtonTapped), for: .touchUpInside)
        return button
    }()
    
    lazy var startStopButton: UIButton = {
       let button = UIButton()
        button.setTitle("Start Navigation", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.addTarget(self, action: #selector(startStopButtonTapped), for: .touchUpInside)
        return button
    }()
    
    
    @objc fileprivate func getDirectionButtonTapped() {
        guard let text = textField.text else { return }
        showMapRoute = true
        textField.endEditing(true)
        
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(text) { (placemarks, err) in
            if let err = err {
                print(err.localizedDescription)
                return
            }
            guard let placemarks = placemarks,
                  let placemark = placemarks.first,
                  let location = placemark.location
            else {return}
            let destinationCoordinate = location.coordinate
             self.mapRoute(destinationCoordinate: destinationCoordinate)
        }
    }
    
    fileprivate func mapRoute(destinationCoordinate: CLLocationCoordinate2D) {
        guard let sourceCoordinate = locationManeger.location?.coordinate else { return }
        let sourcePlacemark = MKPlacemark(coordinate: sourceCoordinate)
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
        
        let sourceItem = MKMapItem(placemark: sourcePlacemark)
        let destinationItem = MKMapItem(placemark: destinationPlacemark)
        
        let routeRequest = MKDirections.Request()
        routeRequest.source = sourceItem
        routeRequest.destination = destinationItem
        routeRequest.transportType = .automobile
        
        let direction = MKDirections(request: routeRequest)
        direction.calculate { (response, err) in
            if let err = err {
                print(err.localizedDescription)
                return
            }
            guard let response = response, let router = response.routes.first else {return}
            self.router = router
            self.mapView.addOverlay(router.polyline)
            self.mapView.setVisibleMapRect(router.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16), animated: true)
            
            self.getRouteSteps(route: router)
        }
    }
    
    fileprivate func getRouteSteps(route: MKRoute) {
        
    }
    
    @objc fileprivate func startStopButtonTapped() {
        
    }
    
    lazy var locationManeger: CLLocationManager = {
          let locationManager = CLLocationManager()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            handleAuthrizationStatus(locationManager: locationManager, status: CLLocationManager.authorizationStatus())
        } else {
            print("Location services are not enabled")
        }
        
        return locationManager
    }()
    
    fileprivate func centerViewToUserLocation(center: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(center: center, latitudinalMeters: locationDistance, longitudinalMeters: locationDistance)
        mapView.setRegion(region, animated: true)
    }
    
    fileprivate func handleAuthrizationStatus(locationManager: CLLocationManager, status: CLAuthorizationStatus) {
        switch status {
            
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        case .restricted:
            //
            break
        case .denied:
            //
            break
        case .authorizedAlways:
            //
            break
        case .authorizedWhenInUse:
            if let center = locationManager.location?.coordinate {
                centerViewToUserLocation(center: center)
            }
            break
        @unknown default:
            //
            break
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6
        setupConstraints()
        mapView.delegate = self
        mapView.showsUserLocation = true
        locationManeger.startUpdatingLocation()
//        checkLocationServices()
    }
    
    private func setupConstraints() {
        
        stack(.vertical)(directionLabel.insetting(by: 16),
                         stack(.horizontal, spacing: 16)(textField, getDirectionButton).insetting(by: 16),
                         startStopButton.insetting(by: 16),
                         mapView).fillingParent(relativeToSafeArea: true).layout(in: view)
        
//        view.addSubview(mapView)
//        mapView.translatesAutoresizingMaskIntoConstraints = false
//        
//        NSLayoutConstraint.activate([
//        
//            mapView.topAnchor.constraint(equalTo: view.topAnchor),
//            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//        ])
    }
    
//    private func setupLocationManager() {
//        self.locationManeger.delegate = self
//        self.locationManeger.desiredAccuracy = kCLLocationAccuracyBest
//    }
    
//    private func checkLocationServices() {
//        if CLLocationManager.locationServicesEnabled() {
//            setupLocationManager()
//            checkLocationAutorization()
//        } else {
//            // erorr
//        }
//    }
    
    private func checkLocationAutorization() {
        switch CLLocationManager.authorizationStatus() {
            
        case .notDetermined:
            locationManeger.requestWhenInUseAuthorization()
        case .restricted:
            //
            break
        case .denied:
            //
            break
        case .authorizedAlways:
            break
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            locationManeger.startUpdatingLocation()
            break
            
        @unknown default:
            fatalError()
        }
    }
}

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !showMapRoute {
            if let location =  locations.last {
                let center = location.coordinate
                centerViewToUserLocation(center: center)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        handleAuthrizationStatus(locationManager: locationManeger, status: status)
    }
}

extension MapViewController: MKMapViewDelegate {
    
}

