//
//  WorkoutManager.swift
//
//  Created by Grant Perry on 1/24/23.
// Modified: Tuesday January 9, 2024 at 4:43:43 PM

import SwiftUI
import Observation
import HealthKit
import CoreLocation
import UIKit
import Combine

@Observable
/// ``WorkoutManager``
/// Manages workout sessions, integrating with HealthKit to track and record various workout metrics like heart rate, energy burned, and distance. It also manages location updates during outdoor workouts to map the route taken.
class WorkoutManager: NSObject, CLLocationManagerDelegate {

	// MARK: - Properties for Tracking and Workout Session
	var distanceTracker: DistanceTracker // Manages distance-related metrics for workouts.
	var weatherKitManager: WeatherKitManager // Manages weather information for workouts.
	var geoCodeHelper: GeoCodeHelper // Helps with geocoding locations to city names.
	var initialLocation: CLLocation? // Marks the starting point of the workout.
	var workout: HKWorkout? // Represents a HealthKit workout.
	var session: HKWorkoutSession? // Controls the workout session lifecycle.
	var builder: HKLiveWorkoutBuilder? // Assembles workout data for ongoing sessions.
	let healthStore = HKHealthStore() // Provides an interface to the HealthKit store.
	var collectedLocationsFromDevice: [CLLocation] = [] // the collected waypoints from the workout for workoutBuilder
	var thisMetadata: [String : Any] = [:] // temp holder for building the metadata 


	// MARK: - Workout Metadata Properties
	var thisAddress = "" // Holds the detailed address for workout metadata.
	var thisCity = "" // Stores the city name for workout metadata.
	var thisStreet = ""
	var thisName = ""

	// MARK: - State Tracking Properties
	var workoutSessionState: HKWorkoutSessionState = .notStarted // Current state of the workout session.
	var heading = "" // Current directional heading.
	var isLocateMgr: Bool = false // Indicates if CLLocationManager is actively used.

	// MARK: - Workout Metrics Properties
	var distanceCollected: Double = 0 // Cumulative distance collected during the workout.
	var averageHeartRate: Double = 0 // Average heart rate measured during the workout.
	var heartRate: Double = 0 // Current heart rate.
	var activeEnergy: Double = 0 // Amount of active energy burned.
	var workoutDistance: Double = 0 // Total distance covered during the workout.
	var stepCounter: Double = 0 // Total number of steps counted.
	var routeHeading: Double = 0 // Directional heading of the workout route.
	var course: Double = 0 // Course direction during the workout.
	var workoutAltitude: Double = 0 // Altitude reached during the workout.
	let minimumAccuracy: CLLocationAccuracy = 50.0 		// Sets the threshold for acceptable GPS accuracy in meters to determine if a location update is reliable enough to be used.

	// MARK: - Location and Route Management
	let WMDelegate = CLLocationManager() // Handles location updates.
	private var routeBuilder: HKWorkoutRouteBuilder? // Constructs the workout route.

	/// ``selectedWorkout``
	/// Property to select and start a workout session with the specified workout type.
	/// - Note: Setting this property initiates a new workout session based on the specified workout type.
	var selectedWorkout: HKWorkoutActivityType? {
		didSet {
			guard let selectedWorkout = selectedWorkout else { return }
			startWorkout(workoutType: selectedWorkout)
		}
	}
	var gpsAccuracyCheckRetries = 0
	let maxRetries = 3  // Maximum allowed retries


	// Initializer and other methods would follow here...

	/// ``WorkoutManager/init
	/// Initializes a new instance of WorkoutManager with the specified parameters.
	/// - Parameters:
	///   - distanceTracker: Tracks distance of workout.
	///   - initialLocation: Starting location of the workout.
	///   - workout: The HealthKit workout instance.
	///   - workoutSessionState: The initial state of the workout session.
	///   - heading: Initial heading.
	///   - isLocateMgr: Flag indicating if CLLocationManager is used.
	///   - distanceCollected: Initial distance collected.
	///   - averageHeartRate: Initial average heart rate.
	///   - heartRate: Initial heart rate.
	///   - activeEnergy: Initial active energy burned.
	///   - workoutDistance: Initial workout distance.
	///   - stepCounter: Initial step count.
	///   - routeHeading: Initial route heading.
	///   - course: Initial course.
	///   - workoutAltitude: Initial workout altitude.
	///   - session: HealthKit workout session.
	///   - builder: HealthKit live workout builder.
	///   - routeBuilder: HealthKit workout route builder.
	///   - selectedWorkout: Type of workout selected.
	internal init(distanceTracker: DistanceTracker, weatherKitManager: WeatherKitManager, geoCodeHelper: GeoCodeHelper, initialLocation: CLLocation? = nil, workout: HKWorkout? = nil, session: HKWorkoutSession? = nil, builder: HKLiveWorkoutBuilder? = nil, thisAddress: String = "", thisCity: String = "", workoutSessionState: HKWorkoutSessionState = .notStarted, heading: String = "", isLocateMgr: Bool = false, distanceCollected: Double = 0, averageHeartRate: Double = 0, heartRate: Double = 0, activeEnergy: Double = 0, workoutDistance: Double = 0, stepCounter: Double = 0, routeHeading: Double = 0, course: Double = 0, workoutAltitude: Double = 0, routeBuilder: HKWorkoutRouteBuilder? = nil, selectedWorkout: HKWorkoutActivityType? = nil) {
		self.distanceTracker = distanceTracker
		self.weatherKitManager = weatherKitManager
		self.geoCodeHelper = geoCodeHelper
		self.initialLocation = initialLocation
		self.workout = workout
		self.session = session
		self.builder = builder
		self.thisAddress = thisAddress
		self.thisCity = thisCity
		self.workoutSessionState = workoutSessionState
		self.heading = heading
		self.isLocateMgr = isLocateMgr
		self.distanceCollected = distanceCollected
		self.averageHeartRate = averageHeartRate
		self.heartRate = heartRate
		self.activeEnergy = activeEnergy
		self.workoutDistance = workoutDistance
		self.stepCounter = stepCounter
		self.routeHeading = routeHeading
		self.course = course
		self.workoutAltitude = workoutAltitude
		self.routeBuilder = routeBuilder
		self.selectedWorkout = selectedWorkout
	}

	/// ``startWorkout(workoutType:)``
	/// gets called when the button is initially pressed
	/// Initializes and starts a new workout session with specified configurations.
	/// - Parameter workoutType: The type of workout to start, specified as an `HKWorkoutActivityType`.
	/// This method configures a new `HKWorkoutSession` with outdoor location tracking and prepares the `HKLiveWorkoutBuilder` for data collection. It requests location permissions and begins collecting location updates to map the workout route.
	func startWorkout(workoutType: HKWorkoutActivityType) {
		initialLocation = nil // Resets the initial location at the start of a new workout.

		// Configure workout session.
		let configuration = HKWorkoutConfiguration()
		configuration.activityType = workoutType
		configuration.locationType = .outdoor

		do {
			// Attempt to create a workout session and its associated builder.
			session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
			builder = session?.associatedWorkoutBuilder()

			// Set the delegates for session and builder to self to handle workout session events.
			session?.delegate = self
			builder?.delegate = self
		} catch {
			return // If an error occurs during session creation, the function exits early.
		}

		// Configure the data source for the workout builder.
		builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)

		// Start the workout session and data collection.
		let startDate = Date()
		session?.startActivity(with: startDate)
		builder?.beginCollection(withStart: startDate) { success, error in
			// Callback for when the data collection begins. Placeholder for further implementation.
		}

		// Prepare the CLLocationManager for location updates.
		WMDelegate.delegate = self
		DispatchQueue.main.async { [self] in
			WMDelegate.requestWhenInUseAuthorization() // Request location permissions.
		}
		WMDelegate.distanceFilter = distanceTracker.isPrecise ? 1 : 10 // Set location update frequency.
		WMDelegate.desiredAccuracy = distanceTracker.isPrecise ? kCLLocationAccuracyBest : kCLLocationAccuracyNearestTenMeters // Set location accuracy.
		WMDelegate.allowsBackgroundLocationUpdates = true // Allow location updates in the background.
		WMDelegate.startUpdatingLocation() // Start receiving location updates.

		// Initialize routeBuilder to record the workout route.
		routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: nil)
	}

	// MARK: - Build the metadata and end the current workout session
	/// ``endWorkoutbuilder()``
	/// Ends the current workout session and resets the relevant workout variables.
	/// This method concludes the workout session by signaling its end to the `session` object 
	/// and resetting the workout variables using `distanceTracker.cleanVars`.
	func endWorkoutbuilder() async {
		// go build the metaData for the routeBuilder
		Task {
			do {
//				thisMetadata = [:] // bleach thisMetadata
				thisMetadata = await buildRouteMetadata()!
			}
		}
		self.session?.end() // Stops receiving location updates.
		WMDelegate.stopUpdatingLocation() // Resets workout-related variables to their initial states.
		distanceTracker.cleanVars = true // bleach/init the properties
	}
// MARK: -> locationManager helpers

	/// ``locationManager(_:didUpdateLocations:)``
	/// Called when new locations are available from the `CLLocationManager`. It processes the received locations to update the workout session's data, 
	/// including the route being taken, altitude, and direction.
	/// - Parameters:
	///   - manager: The `CLLocationManager` instance that generated the update event.
	///   - workoutLocations: An array of `CLLocation` objects representing the updated locations.
	///
	/// This method ensures that location updates are only processed if the workout session is running. It checks for the accuracy of the location data, 
	/// setting the initial location for the workout if it meets the accuracy requirements. The method continues to collect and process location data,
	/// updating various workout metrics such as altitude and course direction. It also adds the collected location data to a route builder for visualization and analysis.
	func locationManager(_ manager: CLLocationManager, didUpdateLocations thisGPSLocation: [CLLocation]) {
		guard let currentLocation = thisGPSLocation.last else {
			distanceTracker.isInitialLocationObtained = false
			return
		}
		if workoutSessionState == .notStarted { return } // Checks if the workout session state is not started and returns early to prevent further execution.
		if workoutSessionState == .running && initialLocation == nil { // Processes the location updates only if the workout session is running and the initial location has not yet been set.
			// Look for the first location update that meets the minimum accuracy requirement to set as the initial location.
			if let accurateLocation = thisGPSLocation.first(where: { $0.horizontalAccuracy <= minimumAccuracy }) {
				initialLocation = accurateLocation // Sets the found accurate location as the initial location for the workout.
				distanceTracker.isInitialLocationObtained = true // Marks that a reliable initial location has been obtained.
				distanceTracker.ShowEstablishGPSScreen = false // Hides any UI element indicating the GPS is still establishing.
			} else {
				// If no location update meets the accuracy requirement, marks the initial location as not obtained.
				distanceTracker.isInitialLocationObtained = false
				distanceTracker.ShowEstablishGPSScreen = true // Shows or updates the UI to indicate GPS accuracy is insufficient.
				print("Location accuracy is insufficient - accuracy: \(thisGPSLocation.first?.horizontalAccuracy ?? 0)")
// TODO: - should this return be there or not? If it breaks, remove it: 3/11/24
				return // don't process any further and wait for additional stronger signal updates
			}
		}

/// 	Initializes an array to hold location data to process added to the route builder.
/// 	This is the logic that collects & builds the location data from the current workout. It collects CLLocations/waypoints
///		and adds them to the `collectedLocationsFromDevice` [collection] and eventually gets added to the routeBuilder when ending workout.
		isLocateMgr = false // Resets the flag indicating whether the location manager is actively being used.
		thisGPSLocation.forEach { collectedLocation in // Iterates over all received location updates to process and collect them.
			course = collectedLocation.course // Updates the current course direction based on the location update.
			heading = CardinalDirection(course: collectedLocation.course).rawValue // Converts the course direction to a readable format.
			workoutAltitude = collectedLocation.altitude // Updates the current workout altitude with the new location's altitude.
			// Adds the processed location to the collection of locations to be added to the route builder.
			collectedLocationsFromDevice.append(
				CLLocation(
					coordinate: collectedLocation.coordinate,
					altitude: collectedLocation.altitude,
					horizontalAccuracy: collectedLocation.horizontalAccuracy,
					verticalAccuracy: collectedLocation.verticalAccuracy,
					course: collectedLocation.course,
					speed: collectedLocation.speed,
					timestamp: collectedLocation.timestamp
				)
			)
		}

		// Calculates the total altitude from all collected locations to determine the average altitude for the workout.
		let totalAltitude = collectedLocationsFromDevice.reduce(0) { $0 + $1.altitude }
		let numberOfLocations = Double(collectedLocationsFromDevice.count)
		// Sets the workout's altitude to the average altitude across all collected locations, if any locations were collected.
		workoutAltitude = numberOfLocations > 0 ? totalAltitude / numberOfLocations : 0

		// Attempts to add the collected locations to the route builder for inclusion in the workout route.
		routeBuilder?.insertRouteData(collectedLocationsFromDevice) { [weak self] success, error in
			guard let self = self else { return }
			if let error = error {
				// Logs any errors encountered while attempting to add location data to the route builder.
				print("Error adding location to the route builder: \(error.localizedDescription)")
			} else {
				// Updates the UI or logs on success to indicate that the location has been successfully added to the builder.
				DispatchQueue.main.async {
					self.distanceTracker.builderDebugStr = "Location successfully added to builder: \(success)"
					self.isLocateMgr = false // Resets the state indicating active location management.
				}
			}
		}
	}

	/// ``locationManager(_:didUpdateHeading:)``
	/// Captures updates to the device's heading, updating the route heading and the UI state for displaying the compass.
	/// - Parameters:
	///   - manager: The `CLLocationManager` instance reporting the event.
	///   - newHeading: The new heading data.
	///
	/// This method sets a flag indicating that the compass view should update its background state to reflect the current heading and updates the `routeHeading` with the true heading value from `newHeading`.
	func locationManager(_ manager: CLLocationManager, didUpdateHeading thisNewHeading: CLHeading) {
		isLocateMgr = true // Indicates an update to the heading, affecting the CompassView appearance.
		routeHeading = thisNewHeading.trueHeading // Stores the true heading for directional calculations.
	}

	/// ``locationManager(_:didChangeAuthorization:)``
	/// Responds to changes in the location services authorization status. It requests authorization if the current status is not determined or explicitly denied.
	/// - Parameters:
	///   - manager: The `CLLocationManager` instance reporting the event.
	///   - status: The new authorization status for the application.
	///
	/// When authorization is either always granted or granted when in use, the method returns without action. If the authorization status is not determined, denied, or restricted, it requests "when in use" authorization. An unknown default case triggers a fatal error, indicating an unexpected scenario that needs addressing.
	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		switch status {
			case .authorizedAlways, .authorizedWhenInUse:
				return
			case .notDetermined, .denied, .restricted:
				WMDelegate.requestWhenInUseAuthorization()
			@unknown default:
				fatalError("Unhandled authorization status")
		}
	}

	/// ``locationManager(_:didFailWithError:)``
	/// Logs errors from the `CLLocationManager`, indicating issues with location services.
	/// - Parameters:
	///   - manager: The `CLLocationManager` instance that encountered the error.
	///   - error: The error that occurred.
	///
	/// This method prints a log message detailing the error encountered by the location manager. This can assist in diagnosing issues with location updates or permissions.
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print("-WorkoutManager LM - Location manager error: \(error.localizedDescription)")
	}

}

extension WorkoutManager {
	// MARK: - State Control
	func pause() {
		session?.pause()
		WMDelegate.stopUpdatingLocation()
	}

	func resume() {
		session?.resume()
		WMDelegate.startUpdatingLocation()
	}

	func togglePause() {
		if distanceTracker.weIsRecording {
			pause()
		} else {
			resume()
		}
	}

	func resetWorkout() {
		selectedWorkout = nil
		initialLocation = nil
		builder = nil
		session = nil
		workout = nil
		distanceCollected = 0
		activeEnergy = 0
		averageHeartRate = 0
		heartRate = 0
		workoutDistance = 0
		stepCounter = 0
		workoutSessionState = .notStarted
	}
}

extension WorkoutManager: HKWorkoutSessionDelegate {

	/// ``workoutSession(_:didChangeTo:from:)``
	/// Notifies the delegate that the state of the `HKWorkoutSession` has changed. This method handles state transitions and performs actions based on the current state of the workout session.
	/// - Parameters:
	///   - workoutSession: The `HKWorkoutSession` that changed state.
	///   - toState: The new state of the workout session.
	///   - fromState: The previous state of the workout session.
	///
	/// Upon state change, this method logs the transition and performs necessary actions such as updating UI elements or stopping data collection based on the new state. If the session ends, it concludes data collection and finalizes the workout and route data.
   func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
	  // Log state transition for debugging.
	  print("Workout session state changed from \(fromState.rawValue) to \(toState.rawValue)")
//	  print("Current view: \(type(of: self).description())\n")
	  let callingFunction = #function
	  print("Called from function: \(callingFunction)\n")

	  // Log call stack to identify caller details in a debug scenario.
	  let stack = Thread.callStackSymbols
	  if stack.count > 1 {
		 print("Caller: \(stack[1]) - and \(stack[0]) \n")
	  }

	  // Update tracking and UI based on the new state.
	  DispatchQueue.main.async { [self] in
		 distanceTracker.weIsRecording = toState == .running // Begin recording workout data if the session is running.
		 workoutSessionState = toState // Update internal state to reflect the new session state.
		 distanceTracker.builderDebugStr = "Builder: " + String(toState.rawValue) // Debug string update.
	  }
	  // MARK: -- End the workout and write data
	  if toState == .ended {
		 // Start of the updated code block
		 Task {
			do {
			   // Ensure metadata is prepared before proceeding
			   if let thisMetadata = await buildRouteMetadata() {
//				  print("[ 2 - didChangeTo - from] Final metadata: \(String(describing: thisMetadata))\n=======================\n")
//				  print("Route successfully added to workout with metadata.")

				  // Proceed with ending data collection and finalizing the workout now that metadata is ready
				  builder?.endCollection(withEnd: Date(), completion: { [self] success, error in
					 if let error = error {
						print("Error ending the collection: \(error.localizedDescription)")
					 } else {
//						print("[2a - didChangeTo] Collection ended successfully: \(success.description)")
//						print("[didChange2] Getting ready to write this discovered metadata:\n\(thisMetadata)")

						// Finalize the workout and attach any collected route data.
						builder?.finishWorkout(completion: { [self] workout, error in
						   DispatchQueue.main.async { [self] in
							  self.workout = workout
							  guard let thisWorkout = workout else {
								 print("Workout is nil, cannot finish the route")
								 return
							  }

							  // Finish the route with the completed workout and provided metadata
							  self.routeBuilder?.finishRoute(with: thisWorkout, metadata: thisMetadata, completion: { (completedRoute, error) in
								 print("HERE IS the actual route metadata at routeBuilder.finishRoute(with:, metadata:, completion:) - 2a:\n\(String(describing: completedRoute))")

								 if let error = error {
									print("Error finishing route: \(error.localizedDescription)")
								 }
							  })
						   }
						})
					 }
				  })

				  // Cease location updates as the workout session has ended.
				  WMDelegate.stopUpdatingLocation()

			   } else {
				  print("Failed to build route metadata.")
			   }
			}
		 }
		 // End of the updated code block
	  }
   }

	/// ``getCityNameFromCoordinatesAsync(latitude:longitude:)``
	/// Asynchronously retrieves the city name for the specified geographic coordinates.
	/// - Parameters:
	///   - latitude: The latitude component of the geographic coordinates.
	///   - longitude: The longitude component of the geographic coordinates.
	/// - Returns: An optional `String` containing the name of the city at the specified coordinates, or `nil` if the city cannot be determined.
	///
	/// This function leverages the `geoCodeHelper.getCityNameFromCoordinates` method, which performs geocoding to find the city name based on latitude and longitude. The asynchronous nature of this function is achieved through the use of a continuation within an `await withCheckedContinuation` block, allowing for seamless integration into async/await patterns in Swift.
	func getCityNameFromCoordinatesAsync(latitude: CLLocationDegrees, longitude: CLLocationDegrees) async -> CLPlacemark? {
		await withCheckedContinuation { continuation in
			geoCodeHelper.getCityNameFromCoordinates(latitude, longitude) { placeMarks in
				continuation.resume(returning: placeMarks)
			}
		}
	}

	func workoutSession(_ workoutSession: HKWorkoutSession,
						didFailWithError error: Error) {
		print("Workout session failed with error: \(error.localizedDescription)")
	}
}

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
	// Type alias for HKQuantityType to simplify the code readability.
	typealias HKQ = HKQuantityType

	/// ``workoutBuilderDidCollectEvent(_:)''
	/// Called when an event is collected during a live workout session.
	/// - Parameter workoutBuilder: The live workout builder that collected the event.
	///
	/// This method processes each collected event to extract and log relevant workout statistics, such as distance walked or run,
	/// based on the sum quantity of the events. It specifically looks for `distanceWalkingRunning` events to update the `distanceCollected`.
	func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
		//      print("liveWorkoutBuilder collected:\n")
		DispatchQueue.main.async { [self] in
			for (quantityType, statistics) in workoutBuilder.allStatistics {
				if let sum = statistics.sumQuantity() {
					print("Sum: \(sum)")
					if quantityType.identifier == HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue {
						let distanceUnit = HKUnit.mile()
						distanceCollected += sum.doubleValue(for: distanceUnit)

						print("distanceCollected sum: \(distanceCollected)\n")
					}
				}
			}
			print("\n")
		}
	}

	/// ``workoutBuilder(_:didFinishWith:error:)''
	/// Called when the HKLiveWorkoutBuilder finishes constructing the workout session, either successfully or with an error.
	/// - Parameters:
	///   - workoutBuilder: The `HKLiveWorkoutBuilder` instance that finished the workout construction.
	///   - workout: The `HKWorkout` instance that has been constructed.
	///   - error: An optional error object indicating why the workout construction failed, if applicable.
	///
	/// This method attempts to finalize the workout route, handles any errors during the route finalization, checks if the workout session is still active to properly end data collection, and logs appropriate messages regarding the success or failure of these operations. It is crucial for ensuring that the workout data is accurately captured and stored.
	func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didFinishWith workout: HKWorkout, error: Error?) {
		// Logs the entry into the method and handles any potential errors encountered during the workout building process.
		if let error = error {
			print("Error with workout builder: \(error.localizedDescription)")
			return
		}
		Task {
			do {
//				thisMetadata = [:] // bleach it
				thisMetadata = await buildRouteMetadata()! // go build the metadata async and wait till it's finished
				print("[ 3 - didChangeTo - from] Final metadata successfully written:\n\(String(describing: thisMetadata))\n=======================\n")
			}
		}
	   print("[didFinishWith] Getting ready to write metadata: \(thisMetadata)")
		// Attempts to finish routing the workout, processing and logging success or any errors encountered.

		routeBuilder?.finishRoute(with: workout, metadata: thisMetadata) { (route, error) in
			if let error = error {
				print("Error finishing route: \(error.localizedDescription)")
			} else {
				print("[didFinishWith] Route successfully added to workout")
				// If the workout session is still active, proceeds to end the collection of data.
				if self.session?.state == .running {
					workoutBuilder.endCollection(withEnd: workout.endDate) { (success, error) in
						if success {
						   // i added next line to try and quell the warnings... take this out if issues 3/14/24
						   self.session = nil
							print("Collection ended successfully")
						   
						} else if let error = error {
							print("Error ending the collection: \(error.localizedDescription)")
						}
					}
				} else {
					print("Workout session is not active, no need to end the collection.")
				}
			}
		}
	}

	/// ``workoutBuilder(_:didCollectDataOf:)''
	/// Called whenever the `HKLiveWorkoutBuilder` collects new data for the specified types during a workout.
	/// - Parameters:
	///   - workoutBuilder: The `HKLiveWorkoutBuilder` instance collecting the workout data.
	///   - collectedTypes: A set of `HKSampleType` objects representing the types of data that have been collected.
	///
	/// Iterates through the set of collected data types, extracting and processing statistics for each type to update the workout's metrics. This function plays a critical role in real-time data processing, allowing the workout session to reflect the most current data.
	func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
		for type in collectedTypes {
			// Ensures the type is an HKQuantityType, casting from HKSampleType for specific processing.
			guard let quantityType = type as? HKQ else { return }

			// Retrieves the accumulated statistics for the specific quantity type up to the current point in the workout.
			// The statistics object contains aggregated data such as sum, average, or most recent value, depending on the quantity type.
			let statistics = workoutBuilder.statistics(for: quantityType)

			// Calls a separate function to update the UI or internal state based on the new statistics.
			// This could involve updating displayed metrics like heart rate, calories burned, or distance traveled.
			updateForStatistics(statistics)
		}
	}

	/// ``updateForStatistics(_:)``
	/// Updates the workout manager's metrics based on the latest statistics collected during the workout.
	/// - Parameter statistics: An optional `HKStatistics` object containing the updated data for a specific health metric.
	///
	/// This method processes the statistics for different health metrics (heart rate, active energy burned, step count, distance walking/running) and updates the corresponding properties of the workout manager. The update occurs on the main thread to ensure any UI bound to these properties can refresh accurately and promptly.
	func updateForStatistics(_ statistics: HKStatistics?) {
		guard let statistics = statistics else { return }

		DispatchQueue.main.async {
			// Determines the type of data the statistics object represents and processes it accordingly.
			switch statistics.quantityType {
				case HKQ.quantityType(forIdentifier: .heartRate):
					// Extracts and updates the most recent and average heart rate values.
					let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
					self.heartRate = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
					self.averageHeartRate = statistics.averageQuantity()?.doubleValue(for: heartRateUnit) ?? 0

				case HKQ.quantityType(forIdentifier: .activeEnergyBurned):
					// Extracts and updates the total active energy burned.
					let energyUnit = HKUnit.kilocalorie()
					self.activeEnergy = statistics.sumQuantity()?.doubleValue(for: energyUnit) ?? 0

				case HKQ.quantityType(forIdentifier: .stepCount):
					// Extracts and updates the total step count.
					let stepUnit = HKUnit.count()
					self.stepCounter = statistics.sumQuantity()?.doubleValue(for: stepUnit) ?? 0

				case HKQ.quantityType(forIdentifier: .distanceWalkingRunning),
					HKQ.quantityType(forIdentifier: .distanceCycling):
					// Extracts and updates the total distance covered for walking/running or cycling.
					let distanceUnit = HKUnit.mile()
					self.workoutDistance = statistics.sumQuantity()?.doubleValue(for: distanceUnit) ?? 0

				default:
					// For any other type of data, no action is taken.
					return
			}
		}
	}

	// build the metadata with address and weather info for the routeBuilder Added: 3/7/24
	/// ``buildRouteBuilderMeta()``
	/// Asynchronously constructs a metadata dictionary for the workout route with weather and location information.
	/// - Returns: A dictionary of type `[String: Any]` containing metadata such as temperature, weather condition symbols, and location details.
	///
	/// This method checks if weather data and city name need to be fetched. If the temperature variable (`tempVar`) in `weatherKitManager` is empty, it triggers a weather data fetch for the current coordinates stored in `distanceTracker`. Similarly, if the address (`thisAddress`) is not set, it attempts to retrieve the city name
	/// using reverse geocoding. It then compiles a metadata dictionary (`thisMetaData`) with the obtained weather and location information, ensuring that both `thisCity` and `thisAddress` are updated by their respective async calls before being added to the dictionary.
	func buildRouteMetadata() async -> [String: Any]? {
		var metadata: [String: Any] = [:]
		var seekWeather = false
		var seekAddr = false // utilized for debugging
		print("HEY! weahterKitManagrer.highTempVar = \(weatherKitManager.highTempVar)")

	   // are there valid coordinates
		if let thisLatitude = initialLocation?.coordinate.latitude,
		   let thisLongitude = initialLocation?.coordinate.longitude {
			// check to see if we even need to fetch weather - may have already been done during routeBuilder
			if weatherKitManager.highTempVar == "" { // go get the weather
				seekWeather = true
				do { // Attempt to async fetch the weather data
				   try await weatherKitManager.getWeather(for: CLLocationCoordinate2D(latitude: thisLatitude, longitude: thisLongitude))
				} catch {
				   print("Failed to fetch weather data: \(error.localizedDescription)")
				}
			}

		   // Add weather data to metadata dictionary
		   metadata["symbol"] = weatherKitManager.symbolVar
		   metadata["highTemp"] = weatherKitManager.highTempVar
		   metadata["lowTemp"] = weatherKitManager.lowTempVar
		   metadata["windSpeed"] = weatherKitManager.windSpeedVar
		   metadata["windDirection"] = weatherKitManager.windDirectionVar

		   // determine if we even need to fetch - may have already been done
		   if self.thisAddress.isEmpty {
			  //			if self.thisAddress.isEmpty {
			  // go get the address async
			  seekAddr = true
			  // build the address data from the placemark lookup
			  let thisPlacemark = await getCityNameFromCoordinatesAsync(latitude: thisLatitude, longitude: thisLongitude)

			  // Add address data to metadata dictionary
			  metadata["city"] = thisPlacemark?.locality
			  metadata["street"] = thisPlacemark?.thoroughfare
			  metadata["name"] = thisPlacemark?.name
		   } else {
			  // not found - bleach
			  metadata["city"] = ""
			  metadata["street"] = ""
			  metadata["name"] = ""
		   }
		} else {
		   // Use the existing address info if already available
		   metadata["city"] = thisCity
		   metadata["street"] = thisStreet
			metadata["name"] = thisName
		}

		print("Address query was \(seekAddr ? "" : "not ") necessary.\n")
		print("Weather query was \(seekWeather ? "" : "not ") necessary.\n")
		print("---> Metadata for route builder: \(metadata)\n--------------------------------------\n")
		return metadata
	}

	// Request authorization to access Healthkit.
	func requestHKAuth() {

		typealias HKQ = HKQuantityType

		// The quantity type to write to the health store.
		let typesToShare: Set = [HKQ.workoutType()]

		// The quantity types to read from the health store.
		let typesToRead: Set = [
			HKQ.quantityType(forIdentifier: .heartRate)!,
			HKQ.quantityType(forIdentifier: .activeEnergyBurned)!,
			HKQ.quantityType(forIdentifier: .distanceWalkingRunning)!,
			HKQ.quantityType(forIdentifier: .distanceCycling)!,
			HKQ.quantityType(forIdentifier: .stepCount)!,
			HKQ.quantityType(forIdentifier: .bodyTemperature)!,
			HKObjectType.activitySummaryType()
		]

		// Request authorization for those quantity types
		healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
			// Handle error.
		}
	}
}

extension HKWorkoutSession {
	func end(completion: ((Error?) -> Void)? = nil) {
		let endWorkoutOperation = BlockOperation {
			self.end()
		}

		endWorkoutOperation.completionBlock = {
			completion?(nil)
		}

		endWorkoutOperation.start()
	}
}

extension HKWorkoutRouteBuilder {
	/// ``finishRouteAsync(with:metadata:)``
	/// Asynchronously finalizes a workout route with the given workout and metadata, returning the created `HKWorkoutRoute` object.
	/// - Parameters:
	///   - workout: The `HKWorkout` instance for which the route is being finalized.
	///   - metadata: A dictionary containing metadata to be associated with the route.
	/// - Returns: An optional `HKWorkoutRoute` object, representing the finalized workout route.
	/// - Throws: An error if the route could not be finalized.
	///
	/// Wraps the callback-based `finishRoute(with:metadata:)` method in an async-await pattern, utilizing `withCheckedThrowingContinuation` to bridge the gap between callback and modern Swift concurrency paradigms.
	func finishRouteAsync(with workout: HKWorkout, metadata: [String: Any]?) async throws -> HKWorkoutRoute? {
		return try await withCheckedThrowingContinuation { continuation in
			// Invoke the original `finishRoute` method, providing a continuation to handle the callback response.
			self.finishRoute(with: workout, metadata: metadata) { (route, error) in
				if let error = error {
					// If an error occurs, resume the continuation by throwing the error.
					continuation.resume(throwing: error)
				} else {
					// On successful route finalization, resume the continuation by returning the created route.
					continuation.resume(returning: route)
				}
			}
		}
	}
}




