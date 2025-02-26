//
//  currentLocationDAO.swift
//  Weather
//
//  Created by sento kiryu on 2/11/25.
//
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    public let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    var nameOfCity: String?
    var callable: (()->Void)!
    var rejectCallable: (()->Void)!
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func setCallable(from vc: ViewController){
        callable = vc.finish
        rejectCallable = vc.showNoPermissionsError
    }
    
    
    func requestLocationPermission(){
        if locationManager.authorizationStatus == .notDetermined ||
            locationManager.authorizationStatus == .denied ||
            locationManager.authorizationStatus == .restricted {
            locationManager.requestWhenInUseAuthorization()
        } else if locationManager.authorizationStatus == .authorizedAlways || locationManager.authorizationStatus == .authorizedWhenInUse{
            self.getCurrentLocation()
        }
    }
    
    func getCurrentLocation() {
        if locationManager.authorizationStatus == .authorizedWhenInUse ||
           locationManager.authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        locationManager.stopUpdatingLocation()
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let placemark = placemarks?.first {
                self?.nameOfCity = placemark.locality ?? "Unknown"
                self?.callable()
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if self.getIfAllowed(){
            self.getCurrentLocation()
        } else {
            self.rejectCallable()
        }
    }
    
    func getIfAllowed() -> Bool{
        return locationManager.authorizationStatus == .authorizedAlways || locationManager.authorizationStatus == .authorizedWhenInUse
    }
}
