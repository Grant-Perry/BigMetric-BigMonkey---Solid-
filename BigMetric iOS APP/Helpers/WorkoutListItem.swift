//
//  WorkoutListItem.swift
//  BigMetric
//
//  Created by Grant Perry on 5/31/23.
//

import SwiftUI
import HealthKit
import CoreLocation
import MapKit

// this is the full map view with polyLine overlay view

struct WorkoutListItem: View {
	@State var workout: HKWorkout
	var workoutUtility = WorkoutUtility()
	let mapView: MKMapView = MKMapView()
	@State var healthStore = HKHealthStore()
	@State var locations: [CLLocation]? 					= nil
	@State var regionLatLongHeight:CLLocationDistance	= 2000 // feet
	@State private var CityState: String?
	@State private var lastCoordinates: CLLocationCoordinate2D?
	@State var longitude: CLLocationDegrees?
	@State var latitude: CLLocationDegrees?

	// this is the map view displayed when user selects a workout from the List


	var body: some View {
		NavigationLink {
			VStack {
				// on initial load, locations = nil so this part of the block does not run until
				// locations is populated with s [CLLocation] of the workout
				// it's nil until it's not - after the async

				if let locations = self.locations {
					VStack {
						Text("\(self.formatDateName())")
							.theHead()
					}
					VStack {
						Text("Distance: \(String(format: "%.2f", locations.calcDistance))") +
						Text(" | Duration: \(formatDuration(duration: workout.duration))") +
						Text(" | Calories: \(Int(workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0))")
					}
					.headSmall()
					Text("Found \(locations.count) waypoints")
						.font(.caption)
					//  MARK: - THE MAP displayed
					MapView(mapView:mapView)
						.ignoresSafeArea()

					//  THIS SECTION IS about 85%... fall back to MapView for now
					//					Map {
					//						MapPolyline(coordinates: holdRouteCoords ?? [])
					//							.stroke(gradient)
					//					}

				}
			}
			Spacer()
				.task {
					guard let routes = await getWorkoutRoute(workout: workout), !routes.isEmpty else {
						self.locations = []
						holdRouteCoords = []
						return
					}
					if routes.count > 1 {
						let s: LocalizedStringKey = "found ^[\(routes.count) route sample] (inflect: true)"
						print("\(s)")
					}
					// process only the first route
					self.locations = await getCLocationDataForRoute(routeToExtract: routes[0])
					// Focus locations on the main thread, no need to delay
					DispatchQueue.main.async {
						self.focusLocations()
					}
				}
		}

		// MARK: - the list view
	label: {
			WorkoutMetricsView(workout: workout)
	}

	}

	func workoutMetricsViewORIG() -> some View {
		return HStack(spacing: 10) {
			let workoutActivityType = workout.workoutActivityType
			let workoutIconEnum = WorkoutIcon(hkType: workoutActivityType)

			Image(systemName: workoutIconEnum.icon).foregroundColor(workoutIconEnum.colors)

			Text("\(workoutUtility.formatDate(workout: workout))")
				.theRows()
			Text("\(String(format: "%.2f", workoutUtility.workoutDistance ?? 0.0))")
				.font(.caption)
				.onAppear {
					Task {
						do {
							let distance		= try await workoutUtility.getWorkoutDistance(workout)
							let workoutDistance	= distance
						} catch {
							// Handle any errors here
							print("Error: \(error)")
						}
					}
				}
		}
		.font(.caption)
		.onAppear {
			// Move the data fetching logic here, so it's triggered when the row appears
			Task {
				let hasCoords = await workoutUtility.calcNumCoords(workout)
				let numRouteCoords = hasCoords
			}
		}
	}
}

extension WorkoutListItem {

		func focusLocations() {
		if let coordinates 	= processLocations(self.locations) {
			let delegate 		= MapViewDelegate()

			mapView.delegate 	= delegate
			let polyLine 		= MKPolyline(coordinates: coordinates,
													 count: coordinates.count)
			let region 			= MKCoordinateRegion(center: coordinates[0],
																latitudinalMeters: regionLatLongHeight,
																longitudinalMeters: regionLatLongHeight)

			mapView.addOverlay(polyLine)
			mapView.setCenter(coordinates[0], animated: true)
			mapView.setRegion(region, animated: true)
			holdRouteCoords = coordinates // used in the newer MapPolyline( method
		} else {
			return
			// Handle the case where there are no valid coordinates
		}
	}

	

	func formatDateName() -> String {
		let dateToStringFormatter 			= DateFormatter()
		dateToStringFormatter.dateFormat = "MMMM d, yyyy"

		return dateToStringFormatter.string(from: workout.startDate)
	}

	func processLocations(_ locations: [CLLocation]?) -> [CLLocationCoordinate2D]? {
		guard let validLocations = locations?.filter({ $0.coordinate.latitude != 0 || $0.coordinate.longitude != 0 }), validLocations.count > 0 else {
			return nil
		}
		let coordinates = validLocations.map({ $0.coordinate })
		return coordinates
	}

	
}



