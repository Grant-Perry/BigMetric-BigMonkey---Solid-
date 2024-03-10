//
//  GeoCode.swift
//  howFar Watch App
//
//  Created by: Grant Perry on 4/18/23.
//    Modified: Wednesday November 1, 2023 at 4:59:14 PM
//

import SwiftUI
import Observation
//import Combine
import CoreLocation

/// UTILIZATION:
/// getAddressFromCoordinates(latitude: latitude, longitude: longitude) { address in
/// 	if let address = address {
/// 			print("Address: \(address)")
/// 				} else {
/// 						print("Failed to get address")							}}

@Observable
class GeoCodeHelper: NSObject {
	internal init(distanceTracker: DistanceTracker) {
		self.distanceTracker = distanceTracker
	}
	var distanceTracker: DistanceTracker
	//   @EnvironmentObject var distanceTracker: DistanceTracker

	func getAddressFromCoordinates(_ latitude: CLLocationDegrees,
											 _ longitude: CLLocationDegrees,
											 completion: @escaping (String?) -> Void) {
		let location = CLLocation(latitude: latitude, longitude: longitude)
		let geocoder = CLGeocoder()

		geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
			if let error 	= error {
				print("Reverse geocoding failed with error: \(error.localizedDescription)")
				completion(nil)
				return
			}

			if let placemark = placemarks?.first {
				let address = "\(placemark.subThoroughfare ?? ""), \(placemark.thoroughfare ?? ""), \(placemark.locality ?? ""), \(placemark.administrativeArea ?? ""), \(placemark.postalCode ?? ""), \(placemark.country ?? "")"
				print("Address: \(address) - lat: \(latitude) - long: \(longitude) - [getAddressFromCoordinates]\n")
				completion(address)
			} else {
				print("No address found for the given coordinates")
				completion(nil)
			}
		}
	}

	/*  UTILIZATION:
	 getCityNameFromCoordinates(latitude: latitude, longitude: longitude) { cityName in
	 if let cityName = cityName {
	 print("City name: \(cityName)")
	 } else {
	 print("Failed to get city name")
	 }
	 }
	 */
	func getCityNameFromCoordinates(_ latitude: CLLocationDegrees, _ longitude: CLLocationDegrees, completion: @escaping (String?) -> Void) {
		let location = CLLocation(latitude: latitude, longitude: longitude)
		let geocoder = CLGeocoder()

		geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
			if let error = error {
				print("Reverse geocoding failed with error: \(error.localizedDescription)")
				completion(nil)
				return
			}

			if let placemark = placemarks?.first, let city = placemark.locality {
				print("city name: \(city) - [getCityNameFromCoordinates]\n")
				completion(city)
			} else {
				print("No city found for the given coordinates  - lat: \(latitude) - long: \(longitude) - [getCityNameFromCoordinates]\n")
				completion(nil)
			}
		}
	}

	/* this func makes it a bit easier to getCityName because it fetches the lat & long from the distanceTracker location manager
	 UTILIZATION:
	 getCityNameHelper { address in
	 print("Returned address: \(address)")
	 }

	 This function will call the completion handler with the address or an error message, and you can handle the result in the provided closure.
	 */
	func getCityNameHelper(_ lat: CLLocationDegrees, _ long: CLLocationDegrees, completion: @escaping (String) -> Void) {
		//      let lat = distanceTracker.currentCoords.latitude
		//      let long = distanceTracker.currentCoords.longitude

		getCityNameFromCoordinates(lat, long) { gotCityName in
			if let city = gotCityName {
				print("City Name: \(city) - lat: \(lat) - long: \(long) - [getCityNameHelper]\n")
				completion(city)
			} else {
				print("Failed to get address")
				completion("Failed to get address")
			}
		}
	}
}

