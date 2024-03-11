//  GeoCode.swift
//
//  Created by: Grant Perry on 4/18/23.
//    Modified: Monday March 11, 2024 at 9:13:17 AM

import SwiftUI
import Observation
import CoreLocation

@Observable
class GeoCodeHelper: NSObject {
	internal init(distanceTracker: DistanceTracker) {
		self.distanceTracker = distanceTracker
	}
	var distanceTracker: DistanceTracker

	/// ``getAddressFromCoordinates(_:longitude:completion:)``
	/// Asynchronously retrieves the full address corresponding to the specified latitude and longitude, using reverse geocoding.
	/// - Parameters:
	///   - latitude: The latitude of the location as `CLLocationDegrees`.
	///   - longitude: The longitude of the location as `CLLocationDegrees`.
	///   - completion: A closure that takes an optional `String` and returns `Void`. This closure is called with the address as a `String` if 
	///   reverse geocoding is successful, or `nil` if it fails.
	///
	/// This function initializes a `CLLocation` with the provided coordinates and uses `CLGeocoder` to perform reverse geocoding. On success,
	///  it formats and returns the full address. On failure, it logs an error message and returns `nil`.
	func getAddressFromCoordinates(_ latitude: CLLocationDegrees, _ longitude: CLLocationDegrees,
								   completion: @escaping (CLPlacemark?) -> Void) {
		// Initialize a CLLocation object with the provided latitude and longitude.
		let location = CLLocation(latitude: latitude, longitude: longitude)
		// Create an instance of CLGeocoder for reverse geocoding.
		let geocoder = CLGeocoder()

		// Perform reverse geocoding on the location.
		geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
			// Check if an error occurred during reverse geocoding.
			if let error = error {
				// Log the error message.
				print("Reverse geocoding failed with error: \(error.localizedDescription)")
				// Call the completion handler with nil to indicate failure.
				completion(nil)
				return
			}

			// Attempt to extract the first placemark from the results.
			if let placemark = placemarks?.first {
				// Construct the full address from the components of the placemark.
				let address = "\(placemark.subThoroughfare ?? ""), \(placemark.thoroughfare ?? ""), \(placemark.locality ?? ""), \(placemark.administrativeArea ?? ""), \(placemark.postalCode ?? ""), \(placemark.country ?? "")"
				// Log the obtained address for debugging purposes.
				print("Address: \(address) - lat: \(latitude) - long: \(longitude) - [getAddressFromCoordinates]\n")
				// Call the completion handler with the formatted address.
				completion(placemark)
			} else {
				// Log a message indicating that no address could be found.
				print("No address found for the given coordinates")
				// Call the completion handler with nil to indicate that no address was found.
				completion(nil)
			}
		}
	}



/// ``getCityNameFromCoordinates(_:longitude:completion:)``
/// Asynchronously retrieves the city name for the given latitude and longitude using reverse geocoding.
/// - Parameters:
///   - latitude: The latitude of the location as `CLLocationDegrees`.
///   - longitude: The longitude of the location as `CLLocationDegrees`.
///   - completion: A closure that takes an optional `String` (the city name) and returns `Void`. The closure is executed with the city name 
///   if the operation is successful, or `nil` if it fails.
///
/// This function creates a `CLLocation` object with the specified coordinates and uses `CLGeocoder` to perform reverse geocoding to extract 
/// the city name from the location data. It handles success and failure cases by logging the outcome and executing the completion handler with the result.
func getCityNameFromCoordinates(_ latitude: CLLocationDegrees, 
								_ longitude: CLLocationDegrees,
								completion: @escaping (CLPlacemark?) -> Void) {

	// Initialize a CLLocation object with the provided latitude and longitude for reverse geocoding.
	let location = CLLocation(latitude: latitude, longitude: longitude)
	// Create a CLGeocoder instance for reverse geocoding.
	let geocoder = CLGeocoder()

	// Perform reverse geocoding on the location.
	geocoder.reverseGeocodeLocation(location) { [self] (placemarks, error) in
		// Check for any errors during the reverse geocoding process.
		if let error = error {
			print("Reverse geocoding failed with error: \(error.localizedDescription)")
			// Execute the completion handler with nil to indicate failure.
			completion(nil)
			return
		}

		printPlaceMarks(PM: placemarks!) // for debugging - print out the placemarks

		// Attempt to extract the first placemark and its locality (city name) from the results.
		if let placemark = placemarks?.first {
			// Log the city name for debugging purposes.
			print("placemark: \(placemark)\n-----------\n")
			// Execute the completion handler with the obtained city name.
			completion(placemark)
//			completion(city)
		} else {
			// Log a message if no city name could be found for the given coordinates.
			print("No city found for the given coordinates - lat: \(latitude) - long: \(longitude) - [getCityNameFromCoordinates]\n")
			// Execute the completion handler with nil to indicate that no city name was found.
			completion(nil)
		}
	}
}

// debug function to print the placemarks received from a reverse GEOCode lookup address
	func printPlaceMarks(PM: [CLPlacemark]) {
		print("PRINTING PLACEMARKS: __________\n")
		for placemark in PM {
			let properties = [
				"Name": placemark.name,
				"Thoroughfare": placemark.thoroughfare,
				"SubThoroughfare": placemark.subThoroughfare,
				"Locality": placemark.locality,
				"SubLocality": placemark.subLocality,
				"Administrative Area": placemark.administrativeArea,
				"SubAdministrative Area": placemark.subAdministrativeArea,
				"Postal Code": placemark.postalCode,
				"Country": placemark.country,
				"ISO Country Code": placemark.isoCountryCode,
				// Add other properties you're interested in
			]

			for (label, value) in properties {
				if let value = value {
					print("\(label): \(value)")
				}
			}
			print("-------------------\n")
		}
	}


//	/// getCityNameHelper(_:long:completion:)
//	/// Retrieves the city name for given latitude and longitude coordinates and passes it through a completion handler.
//	/// - Parameters:
//	/// - lat: Latitude of the location as CLLocationDegrees.
//	/// - long: Longitude of the location as CLLocationDegrees.
//	/// - completion: A closure that takes a String and returns Void. It is called with the city name or a failure message.
//	///
//	/// This function leverages getCityNameFromCoordinates to perform reverse geocoding. Upon successful retrieval of the city name, 
//	/// it prints the name along with the latitude and longitude for confirmation and calls the completion handler with the city name.
//	/// In case of failure to retrieve the city name, it logs a failure message and calls the completion handler with a predefined
//	/// failure message, indicating the inability to fetch the city name.
//	func getCityNameHelper(_ latitude: CLLocationDegrees, _ longitude: CLLocationDegrees, completion: @escaping (String) -> Void) {
//		getCityNameFromCoordinates(latitude, longitude) { gotCityName in
//			if let thisCity = gotCityName {
//				print("City Name: \(thisCity) - lat: \(latitude) - long: \(longitude) - [getCityNameHelper]\n")
//				completion(thisCity)
//			} else {
//				print("Failed to get address")
//				completion("Failed to get address")
//			}
//		}
//	}
}

