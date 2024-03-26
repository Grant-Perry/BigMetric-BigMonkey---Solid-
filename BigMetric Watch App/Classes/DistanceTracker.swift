//  DistanceTracker.swift
//
//  Created by Grant Perry on 1/24/23.
//   Modified: Wednesday March 6, 2024 at 12:18:58 AM

import SwiftUI
import Observation
import CoreLocation
import CoreMotion // for the pedometer
import HealthKit

@Observable
/// ``DistanceTracker``
/// A comprehensive manager for tracking workout sessions that integrates real-time GPS tracking, step counting, and workout route building.
/// Leverages `CLLocationManager` for GPS location updates and `CMPedometer` for step tracking. It dynamically adjusts GPS precision and interacts with HealthKit to build and store workout routes.
/// This class encapsulates functionalities like starting/stopping workouts, managing GPS precision, handling location updates, and step counting. It also includes debugging helpers and workout state management.
class DistanceTracker: NSObject, CLLocationManagerDelegate {
// MARK: - Collections for tracking and managing workout data
	var altitudes: [AltitudeDataPoint] = [] // Stores altitude data points.
	var holdCLLocations: [CLLocation] = [] // Temporarily holds CLLocation updates.
	var locationsArray: [CLLocation] = [] // Holds GPS locations for distance calculation.

// MARK: - Constants for unit conversion
	var GPSAccuracy = 99.0 // Accuracy threshold for GPS signal quality.
	let metersToFeet = 0.3048 // Conversion factor from meters -> feet.
	let metersToMiles = 1609.344 // Conversion meters -> miles.
	let metersToYards = 1.0936133 // Conversion meters -> yards.

// MARK: - Debugging and data logging properties
	var builderDebugStr: String = "[nil]" // Debugging for route builder.
	var debugStr: String = "debug" // General debugging information.
	let plusMinus: String = "+=" // Used in debugging calculations.
	var superAuthBug: String = "Not determined" // Tracks authorization issues.
	var superBug: String = "superBug" // Detailed bug tracking.

// MARK: - Formatting and miscellaneous properties
	var formattedTimeString = "00:00:00" // Displays elapsed workout time.
	var formatter = DateComponentsFormatter() // Formats time intervals.
	var locationName = "" // Name of the current location.

// MARK: - GPS-related properties
	var currentCoords = CLLocationCoordinate2D() // Current GPS coordinates.
	var firstLocation: CLLocation? // First location recorded at workout start.
	var lastLocation: CLLocation? // Last recorded location.
	var latitude: CLLocationDegrees? // Current workout latitude.
	var longitude: CLLocationDegrees? // Current workout longitude.
	var LMDelegate = CLLocationManager() // Manages location updates.

// MARK: - HealthKit and workout route properties
	var HKStore = HKHealthStore() // Accesses HealthKit data.
	var routeBuilder = HKWorkoutRouteBuilder(healthStore: HKHealthStore(), device: nil) // Builds a workout route.

// MARK: - Numeric properties for tracking workout metrics
	var altitude: Double = 0 // Current altitude measurement.
	var elapsedTime: Double = 0 // Elapsed time for the current workout session.
	var finalDist: Double = 0 // Final calculated distance for the workout.
	var healthRecordsCount = 0 // Count of health records processed.
	var holdInitialSteps: Int = 0 // Initial steps to adjust step counting.
	var lastDist: Double = 0 // Last recorded distance.
	var lastHapticMile: Int = 0 // Last mile marker for haptic feedback.
	var prevDist: Double = 0 // Previous distance for incremental calculation.
	var segmentDistance: Double = 0 // Distance for the current segment of the workout.
	var speedDist: Double = 0 // Distance used for speed calculations.
	var startStepCnt: Int = 0 // Initial step count at the start of workout.
	var workoutStepCount: Int = 0 // Total step count from the pedometer.

// MARK: - Properties
	var heartRate: Double = 0 { // Current heart rate with didSet to add new readings.
		didSet { heartRateReadings.append(heartRate) }
	}
	var heartRateReadings: [Double] = [] // Stores heart rate readings for average calculation.
	var pedometer: CMPedometer = CMPedometer() // Manages and tracks steps.
	var timer: Timer? // Timer for tracking workout duration.

// MARK: - Dynamic properties with didSet for instant updates
	var cleanVars: Bool = false { // Triggers a reset of all variables to their default states.
		didSet {
			if cleanVars {
				self.cleanVars = false
				resetVars()
			}
		}
	}
	var distance: Double = 0 { 
		didSet {
		   // the hapticMile logic - play haptic if new mile complete and self.isBeep
		   let currentMile = Int(distance)
		   if currentMile > lastHapticMile {
			  lastHapticMile = currentMile // update the currentMile integer value for next mile
			  if self.isBeep {
				 PlayHaptic.tap(PlayHaptic.up)
			  }
		   }
		}
	}
	var isPrecise = true { // Controls the GPS precision for location updates.
		didSet { setPrecision() }
	}

// MARK: - Boolean flags for managing state and user preferences
	var hotColdFirst = true // Manages initial temperature-based logic.
	var isAuthorizedForPreciseLocation = true // Tracks precise location authorization.
	var isBeep = true // Enables beep sound notifications.
	var isHealthUpdate = false // Flags active health data updates.
	var isInitialLocationObtained = false // Indicates if the initial location has been obtained.
	var initRun = true // Indicates if it's the initial run of the tracker.
	var isNotAuthorized = false // Indicates lack of authorization for location updates.
	var isSpeed = true // Toggles between MPH and BPM display.
	var isUpdating = false // Indicates if location updates are active.
	var isWorkoutLive = false // Indicates if a workout session is currently active.
	var ShowEstablishGPSScreen = false // Controls visibility of the GPS establishment screen.
	var showStartText = true // Controls display of start text.
	var startRouteBuilder = true // Flags the start of route building.
	var weIsRecording = false // Flags active workout recording.
	var yardsOrMiles = true // Toggles distance measurement units.
	var YMCalc = true // Determines calculation mode for distance.

// MARK: - Initialization and Setup

//	override init() {
//		super.init()
//		getCLAuth(LMDelegate) // Initialize location services authorization.
//		setupLocationManager() // Configure the location manager for the tracker.
//	}

	internal init(altitudes: [AltitudeDataPoint] = [], holdCLLocations: [CLLocation] = [], locationsArray: [CLLocation] = [], GPSAccuracy: Double = 99.0, builderDebugStr: String = "[nil]", debugStr: String = "debug", superAuthBug: String = "Not determined", superBug: String = "superBug", formattedTimeString: String = "00:00:00", formatter: DateComponentsFormatter = DateComponentsFormatter(), locationName: String = "", currentCoords: CLLocationCoordinate2D = CLLocationCoordinate2D(), firstLocation: CLLocation? = nil, lastLocation: CLLocation? = nil, latitude: CLLocationDegrees? = nil, longitude: CLLocationDegrees? = nil, LMDelegate: CLLocationManager = CLLocationManager(), HKStore: HKHealthStore = HKHealthStore(), routeBuilder: HKWorkoutRouteBuilder = HKWorkoutRouteBuilder(healthStore: HKHealthStore(), device: nil), altitude: Double = 0, elapsedTime: Double = 0, finalDist: Double = 0, healthRecordsCount: Int = 0, holdInitialSteps: Int = 0, lastDist: Double = 0, lastHapticMile: Int = 0, prevDist: Double = 0, segmentDistance: Double = 0, speedDist: Double = 0, startStepCnt: Int = 0, workoutStepCount: Int = 0, heartRate: Double = 0, heartRateReadings: [Double] = [], pedometer: CMPedometer = CMPedometer(), timer: Timer? = nil, cleanVars: Bool = false, distance: Double = 0, isPrecise: Bool = true, hotColdFirst: Bool = true, isAuthorizedForPreciseLocation: Bool = true, isBeep: Bool = true, isHealthUpdate: Bool = false, isInitialLocationObtained: Bool = false, initRun: Bool = true, isNotAuthorized: Bool = false, isSpeed: Bool = true, isUpdating: Bool = false, isWorkoutLive: Bool = false, ShowEstablishGPSScreen: Bool = false, showStartText: Bool = true, startRouteBuilder: Bool = true, weIsRecording: Bool = false, yardsOrMiles: Bool = true, YMCalc: Bool = true) {

		super.init()
		getCLAuth(LMDelegate) // Initialize location services authorization.
		setupLocationManager() // Configure the location manager for the tracker.

		self.altitudes = altitudes
		self.holdCLLocations = holdCLLocations
		self.locationsArray = locationsArray
		self.GPSAccuracy = GPSAccuracy
		self.builderDebugStr = builderDebugStr
		self.debugStr = debugStr
		self.superAuthBug = superAuthBug
		self.superBug = superBug
		self.formattedTimeString = formattedTimeString
		self.formatter = formatter
		self.locationName = locationName
		self.currentCoords = currentCoords
		self.firstLocation = firstLocation
		self.lastLocation = lastLocation
		self.latitude = latitude
		self.longitude = longitude
		self.LMDelegate = LMDelegate
		self.HKStore = HKStore
		self.routeBuilder = routeBuilder
		self.altitude = altitude
		self.elapsedTime = elapsedTime
		self.finalDist = finalDist
		self.healthRecordsCount = healthRecordsCount
		self.holdInitialSteps = holdInitialSteps
		self.lastDist = lastDist
		self.lastHapticMile = lastHapticMile
		self.prevDist = prevDist
		self.segmentDistance = segmentDistance
		self.speedDist = speedDist
		self.startStepCnt = startStepCnt
		self.workoutStepCount = workoutStepCount
		self.heartRate = heartRate
		self.heartRateReadings = heartRateReadings
		self.pedometer = pedometer
		self.timer = timer
		self.cleanVars = cleanVars
		self.distance = distance
		self.isPrecise = isPrecise
		self.hotColdFirst = hotColdFirst
		self.isAuthorizedForPreciseLocation = isAuthorizedForPreciseLocation
		self.isBeep = isBeep
		self.isHealthUpdate = isHealthUpdate
		self.isInitialLocationObtained = isInitialLocationObtained
		self.initRun = initRun
		self.isNotAuthorized = isNotAuthorized
		self.isSpeed = isSpeed
		self.isUpdating = isUpdating
		self.isWorkoutLive = isWorkoutLive
		self.ShowEstablishGPSScreen = ShowEstablishGPSScreen
		self.showStartText = showStartText
		self.startRouteBuilder = startRouteBuilder
		self.weIsRecording = weIsRecording
		self.yardsOrMiles = yardsOrMiles
		self.YMCalc = YMCalc
	}

// MARK: - METHODS

	/// ``setupLocationManager``
	/// Configures the location manager (`LMDelegate`) for the current session.
	/// Sets the delegate to `self`, requests the current location, applies precision settings based 
	/// on `isPrecise`, enables background location updates, and sets the activity type to fitness.
	/// This method ensures that the app is prepared to track the user's location accurately during fitness activities.
	private func setupLocationManager() {
		LMDelegate.delegate = self
		LMDelegate.requestLocation()
		setPrecision()
		LMDelegate.allowsBackgroundLocationUpdates = true // Allows location updates in the background.
		LMDelegate.activityType = .fitness // Sets the activity type to fitness for optimized location tracking.
	}

	/// ``setPrecision``
	/// Adjusts the location manager's precision based on the `isPrecise` property.
	/// A finer precision is used when `isPrecise` is true, and a coarser precision when false.
	/// This function allows dynamic adjustment of location accuracy to balance between precision and power consumption.
	func setPrecision() {
		LMDelegate.distanceFilter = isPrecise ? 1 : 10 // Meters before location update is generated.
		LMDelegate.desiredAccuracy = isPrecise ? kCLLocationAccuracyBest : kCLLocationAccuracyNearestTenMeters // Location accuracy.
	}

	/// ``resetLocationManager``
	/// Resets the location manager to its default state and reconfigures it.
	/// This includes setting the delegate to `nil`, reinitializing `LMDelegate`, and then calling `setupLocationManager`
	/// to apply the default settings. Useful for when you need to refresh or reconfigure the location tracking setup.
	func resetLocationManager() {
		LMDelegate.delegate = nil
		LMDelegate = CLLocationManager()
		getCLAuth(LMDelegate) // Requests location authorization again.
		setupLocationManager() // Reapply location manager configuration.
	}

// MARK: - didUpdateLocations
	/// ``locationManager(_:didUpdateLocations:)``
	/// Called when the CLLocationManager receives new location updates. This method handles updating the application's state based on these updates,
	/// including calculating distance, checking GPS accuracy, and updating UI elements related to GPS tracking.
	/// - Parameters:
	///   - manager: The CLLocationManager instance that produced the location update.
	///   - GPSLocation: An array of CLLocation objects in chronological order, representing the new locations detected.
	///
	/// Detailed operations performed by this method include:
	/// - Validate the last received location.
	/// - Updating GPS accuracy and controlling the visibility of the "Establishing GPS" screen based on whether a valid initial location has been obtained.
	/// - Processing the received location for altitude data and appending it to an array for later use.
	/// - Filtering out locations with poor accuracy (greater than 50 meters) to improve distance calculation accuracy.
	/// - Managing state transitions when the initial location is captured and when the workout session is officially considered to be "live".
	/// - Dynamically calculating the distance covered based on user settings for measurement units (yards or miles).
	func locationManager(_ manager: CLLocationManager, didUpdateLocations GPSLocation: [CLLocation]) {
		// Attempt to get the most recent location update. If it's not available, set flags to indicate the GPS is still establishing.
		guard let isLocation = GPSLocation.last else {
			isInitialLocationObtained = false // Indicates that a valid initial location has not been captured yet.
			ShowEstablishGPSScreen = true // Triggers UI to inform the user that GPS signal is being established.
			return // Exit early since no valid location is available to process.
		}
		// Use the horizontal accuracy of the latest location to set the GPS accuracy indicator in the UI.
		GPSAccuracy = isLocation.horizontalAccuracy // Stores the accuracy of the GPS reading for UI display or logic decisions.
		ShowEstablishGPSScreen = false // Hide the "Establishing GPS" screen since we have at least one valid location.
		// Check if we have already obtained a valid initial location with acceptable accuracy.
		if !isInitialLocationObtained && isLocation.horizontalAccuracy <= 50.0 {
			isInitialLocationObtained = true // Confirm that a reliable initial location has been obtained.
			ShowEstablishGPSScreen = false // Ensure the screen indicating GPS setup is turned off.
// MARK: - reverse geoCode address
			// Reverse geocode the initial location to get a human-readable address or location name.
			let geocoder = CLGeocoder()
			geocoder.reverseGeocodeLocation(isLocation) { [self] (placemarks, error) in
				guard error == nil, let placemark = placemarks?.first else { return } // Safely unwrap the first placemark.
				locationName = placemark.locality ?? "Determining..." // Set the location name, fallback to "Determining..." if unavailable.
			}
		}
		// If we are actively recording a workout session, process the location data.
		if weIsRecording {
			if let location = GPSLocation.last { // Ensure there's at least one new location.
				// Update current latitude, longitude, and construct the currentCoords from the location.
				latitude = Double(location.coordinate.latitude)
				longitude = Double(location.coordinate.longitude)
				currentCoords = location.coordinate // Store the latest coordinate for use in distance calculations or UI updates.
				altitude = location.altitude * metersToFeet // Convert the altitude to feet and store it.
				// Create a new data point for altitude measurements and add it to the altitudes array.
				let newDataPoint = AltitudeDataPoint(value: altitude, dist: distance)
				altitudes.append(newDataPoint)
			}

			// Filter out locations with accuracy worse than 50 meters to improve the reliability of distance calculations.
			let filteredLocations = GPSLocation.filter { $0.horizontalAccuracy <= 50.0 }
			guard !filteredLocations.isEmpty else { return } // If all locations are filtered out, stop processing.
			holdCLLocations = filteredLocations // Store the filtered locations for potential future use.
			locationsArray.append(contentsOf: filteredLocations) // Add the valid locations to the locationsArray for distance calculation.
			// Once we have our first location, set up HealthKit authorization and query for the initial step count if not already done.
			if firstLocation == nil {
				firstLocation = filteredLocations.last // Set the firstLocation to the last of the filtered locations.
				authHealthKitForHeart() // Request authorization for HealthKit to access heart rate data.
				getHKAuth() // Request general HealthKit authorization for other data types.
							// Query the pedometer for the starting step count to calculate steps taken during the workout.
				queryStepCount { steps in
					if let steps = steps {
						self.startStepCnt = steps // Store the initial step count.
						self.holdInitialSteps = steps // Hold the initial steps for calculating steps taken during the workout.
					}
				}
			}

			// Special handling for the first run of the logic to ensure proper setup.
			if initRun {
				// set the appropriate states
				initRun = false // Ensure this initialization logic only runs once.
				isInitialLocationObtained = false // Reset this flag to ensure accurate initial location detection.
				isWorkoutLive = true // Mark the workout session as active/live.
			}

			// Calculate the distance covered in either yards or miles, based on user preference.
			distance = !YMCalc ? locationsArray.calcFromLastLocation / metersToYards : locationsArray.calculatedDistance / metersToMiles
			lastDist = distance // Update the last distance with the current calculation.
			lastLocation = filteredLocations.last // Update the last known location with the most recent valid location.

#if os(watchOS)

#endif
		}
	}

	/// ``locationManager(_:didFailWithError:)``
	/// Called when the CLLocationManager encounters an error during location updates.
	/// - Parameters:
	///   - manager: The CLLocationManager instance that encountered the error.
	///   - error: The error object containing details about what went wrong.
	///
	/// This method handles the error by logging the authorization status and the error description.
	/// It then attempts to request location authorization again, ensuring that location services can potentially recover from the error state.
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print("-- RIGHT HERE **** LMDelegate authorizationStatus = \(LMDelegate.authorizationStatus.rawValue)\n--------\n")
		print("LocationManager LM - locationManager failed with error: \(error.localizedDescription)")
		getCLAuth(manager) // Attempts to re-authorize location services if they fail.
	}

	/// ``startUpdates``
	/// Initiates the process of location and pedometer updates, marking the beginning of a workout recording session.
	/// This method checks the location authorization status and requests authorization if not already granted.
	/// It sets flags to begin recording and initializes the pedometer and location updates. A timer is started to keep track of the elapsed workout time.
	func startUpdates() {
		// Check for location authorization and request it if not already authorized for when in use.
		if self.LMDelegate.authorizationStatus != .authorizedWhenInUse {
			getCLAuth(LMDelegate)
			isNotAuthorized = true // Indicates that the app is not authorized to use location services.
		}

		self.weIsRecording = true // Flag to indicate that workout recording has started.

		// Check if it's necessary to start the route builder for HealthKit and perform authorization.
		if startRouteBuilder {
			getHKAuth() // Request HealthKit authorization.
			startRouteBuilder = false // Prevents multiple initializations of the route builder.
		}

		LMDelegate.startUpdatingLocation() // Starts receiving location updates.

		// Initializes the pedometer to begin counting steps.
		startPedometer(startStop: true)

		// Starts a timer to update the elapsed time every second, useful for tracking workout duration.
		timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
			guard let self = self else { return }
			if self.weIsRecording {
				self.elapsedTime += 1 // Increment the elapsed time by one second.
				self.formattedTimeString = self.stringFromTimeInterval(interval: self.elapsedTime) // Update the formatted time string.
			}
		}
	}

	/// ``locationManager(_:didChangeAuthorization:)``
	/// Responds to changes in the app's location services authorization status.
	/// - Parameters:
	///   - manager: The CLLocationManager instance that observed the change in authorization status.
	///   - status: The new authorization status for location services.
	///
	/// This method attempts to handle changes in location authorization by re-requesting authorization if the status is not determined, denied, or restricted.
	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		switch status {
			case .authorizedAlways, .authorizedWhenInUse:
				// Location services are authorized; no action is needed.
				return
			case .notDetermined, .denied, .restricted:
				getCLAuth(manager) // Attempts to request location authorization again.
			@unknown default:
				fatalError("Encountered an unknown authorization status.")
		}
	}

	/// ``numTimerHours``
	/// Calculates the number of whole hours that have elapsed based on the `elapsedTime` property.
	/// - Returns: The number of hours as an integer.
	///
	/// This utility function divides the total elapsed time in seconds by 3600 to convert to hours, rounding down to the nearest whole number.
	func numTimerHours() -> Int {
		return Int(elapsedTime / 3600) // Converts seconds to hours by dividing by 3600 seconds per hour.
	}

	// Main Distance Calculations - as of 10/29/23 at 11:50:27 AM this is no longer used.
	// the CLLocation.calculatedDistance is now used

//	func calcDistances(currentLocation: CLLocation, prevLocation: CLLocation) {
//		if !YMCalc {  // YARDS
//			if let originalLocation = firstLocation {
//				let thisDistance = currentLocation.distance(from: originalLocation) * metersToYards
//				distance 			= thisDistance * metersToYards
//				plusMinus 			= "="
//			}
//		}
//	}

	/// Stop the CLLocation update
	/// - Parameter resetDist: true = all the counter be reset
	/// - Returns: timeString
	///
	/// ``stopUpdates``
	/// Stops location and pedometer updates and performs cleanup based on the `resetDist` parameter.
	/// - Parameter resetDist: A boolean indicating whether to reset distance-related variables.
	/// - Returns: A string representing the formatted time of the workout session before stopping.
	///
	/// This function halts location updates, stops pedometer tracking, invalidates the timer, and resets the workout recording state.
	/// It optionally clears variables related to distance and location based on `resetDist`.
	/// The function returns the formatted string of the workout duration for potential display or logging purposes.
	func stopUpdates(_ resetDist: Bool) -> String {
		LMDelegate.stopUpdatingLocation() // Stops the location updates.
		startPedometer(startStop: false) // Stops the pedometer.
		timer?.invalidate() // Invalidates the timer to stop elapsed time tracking.
		weIsRecording = false // Marks that recording has stopped.
		firstLocation = nil // Resets the first location marker.
		lastLocation = nil // Clears the last known location.
		let timeString = formattedTimeString // Captures the current formatted time string.
		cleanVars = resetDist // Determines if variable cleaning is requested, triggering didSet if true.
		return timeString // Returns the captured time string.
	}

	/// ``endWorkout``
	/// Finalizes the workout session, saving any necessary data to HealthKit and performing cleanup.
	///
	/// This function constructs a workout object with the defined activity type and time range,
	/// attempts to save the workout route to HealthKit, and stops ongoing location and pedometer updates.
	/// It sets flags to clean up variables, preparing the app state for a new workout session or app closure.
	public func endWorkout() {
		let activityType: HKWorkoutActivityType = .walking // Defines the type of activity for the workout.
		let startDate = Date() // Marks the start date of the workout.
		let endDate = startDate.addingTimeInterval(3600) // Sets the end date to one hour after the start.

		var workOut: HKWorkout { // Constructs a workout object for saving to HealthKit.
			return HKWorkout(activityType: activityType,
							 start: startDate,
							 end: endDate,
							 workoutEvents: nil,
							 totalEnergyBurned: nil,
							 totalDistance: nil,
							 metadata: [:])
		}

		routeBuilder.finishRoute(with: workOut, metadata: nil) { workoutRoute, error in // Attempts to save the constructed route.
			if workoutRoute == nil {
				print("Error saving workout route inside endWorkout with: - \(error!)")
			} else {
				print("Success -> workoutRoute inside endWorkout - Workout = \(workOut)")
			}
		}
		LMDelegate.stopUpdatingLocation() // Stops location updates.
		startPedometer(startStop: false) // Stops the pedometer.
		cleanVars = true // Triggers a cleanup of variables.
	}

	/// ``startPedometer``
	/// Starts or stops the pedometer updates based on the `startStop` parameter.
	/// - Parameter startStop: A boolean indicating whether to start (`true`) or stop (`false`) pedometer updates.
	///
	/// This function manages pedometer updates, allowing for the tracking of steps during a workout session.
	/// It handles starting step counting at midnight for accurate daily step tracking and stops counting upon request.
	func startPedometer(startStop: Bool) {
		if CMPedometer.isStepCountingAvailable() {
			if startStop {
				let calendar = Calendar.current
				let midnight = calendar.startOfDay(for: Date()) // Defines the start time for step counting.
				pedometer.startUpdates(from: midnight) { [self] pedometerData, error in
					if let stepData = pedometerData {
						let pedStepCount = Int(truncating: stepData.numberOfSteps) // Calculates total steps since midnight.
						workoutStepCount = pedStepCount - holdInitialSteps // Adjusts for steps taken prior to the workout start.
					}
				}
			} else {
				DispatchQueue.main.async { [self] in
					pedometer.stopUpdates() // Stops pedometer updates.
				}
			}
		}
	}

	/// ``requestCurrentLocation``
	/// Requests the current location from the CLLocationManager.
	///
	/// This utility function is used to explicitly request a current location update from the location manager.
	/// It ensures that location authorization is requested from the user before attempting to get the location,
	/// improving the likelihood of receiving a valid location update.
	func requestCurrentLocation() {
		getCLAuth(LMDelegate) // Requests location authorization if needed.
		LMDelegate.requestLocation() // Requests a one-time location update.
	}

}

// MARK: - Helpers

extension DistanceTracker { // Miscellaneous helper methods for the DistanceTracker class.

	/// ``stringFromTimeInterval``
	/// Converts a time interval into a formatted string representation.
	/// - Parameter interval: The time interval to format, in seconds.
	/// - Returns: A string formatted as hours, minutes, and seconds (`"HH:MM:SS"`) if hours are present, or just minutes and seconds otherwise (`"MM:SS"`).
	///
	/// This method is utilized to display elapsed time during workout sessions in a human-readable format.
	func stringFromTimeInterval(interval: TimeInterval) -> String {
		let interval = Int(interval)
		let seconds = interval % 60
		let minutes = (interval / 60) % 60
		let hours = (interval / 3600)
		return hours > 0 ? String(format: "%02d:%02d:%02d", hours, minutes, seconds) : String(format: "%02d:%02d", minutes, seconds)
	}

	/// ``blinkRecordBtn``
	/// Toggles the recording state indication on the UI and reverts it back after a specified time.
	/// - Parameters:
	///   - toggleState: Boolean flag to start (`true`) or stop (`false`) the blink effect.
	///   - blinkTime: The duration in seconds for which the blink effect should last.
	///
	/// This method is primarily used to visually indicate the start or stop of recording a workout session via a UI element.
	func blinkRecordBtn(_ toggleState: Bool, _ blinkTime: Int) {
		DispatchQueue.main.async {
			if toggleState { self.isUpdating = true } else { self.isHealthUpdate = true }
			DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(blinkTime)) {
				if toggleState { self.isUpdating = false } else { self.isHealthUpdate = false }
			}
		}
	}

	/// ``resetVars``
	/// Resets all relevant variables to their default state, preparing for a new workout session.
	///
	/// This method clears location data, workout progress, and state flags. It is invoked when a workout session ends or needs to be reset.
	func resetVars() {
		LMDelegate.stopUpdatingLocation()
		resetLocationManager()
		holdCLLocations.removeAll()
		altitudes.removeAll()
		currentCoords = CLLocationCoordinate2D()
		holdCLLocations = []
		locationsArray = []
		longitude = nil
		latitude = nil
		firstLocation = nil
		lastLocation = nil
		initRun = true
		isInitialLocationObtained = false
		isUpdating = false
		isHealthUpdate = false
		weIsRecording = false
		isWorkoutLive = false
		ShowEstablishGPSScreen = false
		debugStr = ""
		superBug = ""
		finalDist = distance // Save final distance for summary.
		distance = 0
		prevDist = 0
		segmentDistance = 0
		elapsedTime = 0
		formattedTimeString = stringFromTimeInterval(interval: elapsedTime) // Reset the timer display.
		heartRate = 0
		speedDist = 0
		lastHapticMile = 0
		GPSAccuracy = 97
	}

	//	}

	func revealPropVals(_ label: String) {
		//		print("workoutManager: \(workoutManager)")
		print("\n---------------------------------------------------------------------------------------")
		print("              [      From -----> \(label)      ]")
		print("---------------------------------------------------------------------------------------\n")
		print("longitude: \(String(describing: longitude))")
		print("latitude: \(String(describing: latitude))")
		print("lastLocation: \(String(describing: lastLocation))")
		print("firstLocation: \(String(describing: firstLocation))")
		print("currentCoords: \(currentCoords)")
		print("altitudes: \(altitudes)")
		print("holdCLLocations: \(holdCLLocations)")
		print("locationName: \(locationName)")
		print("formattedTimeString: \(formattedTimeString)")
		print("formatter: \(formatter)")
		print("timer: \(String(describing: timer))")
		print("debugStr: \(debugStr)")
		print("superBug: \(superBug)")
		print("superAuthBug: \(superAuthBug)")
		print("builderDebugStr: \(builderDebugStr)")
		print("plusMinus: \(plusMinus)")
		print("isBeep: \(isBeep)")
		print("showStartText: \(showStartText)")
		print("isInitialLocationObtained: \(isInitialLocationObtained)")
		print("yardsOrMiles: \(yardsOrMiles)")
		print("YMCalc: \(YMCalc)")
		print("initRun: \(initRun)")
		print("startRouteBuilder: \(startRouteBuilder)")
		print("isAuthorizedForPreciseLocation: \(isAuthorizedForPreciseLocation)")
		print("isUpdating: \(isUpdating)")
		print("isHealthUpdate: \(isHealthUpdate)")
		print("isNotAuthorized: \(isNotAuthorized)")
		print("isWorkoutLive: \(isWorkoutLive)")
		print("weIsRecording: \(weIsRecording)")
		print("cleanVars: \(cleanVars)")
		print("altitude: \(altitude)")
		print("distance: \(String(describing: distance))")
		print("prevDist: \(prevDist)")
		print("speedDist: \(speedDist)")
		print("heartRate: \(heartRate)")
		print("holdDist: \(segmentDistance)")
		print("elapsedTime: \(elapsedTime)")
		print("lastDist: \(lastDist)")
		print("lastHapticMile: \(lastHapticMile)")
		print("startStepCnt: \(startStepCnt)")
		print("healthRecordsCount: \(healthRecordsCount)")
	}

	/// Determinine the average heart rate over a period of time, such as a workout session. It optionally clears the recorded heart rate data.
	func calculateAverageHeartRate(bleach: Bool) -> Double {
		let totalHeartRate = heartRateReadings.reduce(0, +)
		let avgHeartRate = totalHeartRate / Double(heartRateReadings.count)
		// reset heartRateReadings if bleach: true
		if bleach { heartRateReadings = [] }
		return avgHeartRate
	}
}

extension DistanceTracker { // toggle stuff

	func toggleYMBool(_ ymState: Bool)  {
		YMCalc 	= ymState
		_ 			= stopUpdates(true)
	}

	func toggleYMBoolFalse() {
		YMCalc 						= false
	}

	func toggleWeIsRecording(_ RecState: Bool)  {
		weIsRecording 				= RecState
	}
}



