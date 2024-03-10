//
//  BigMetricApp.swift
//  BigMetric Watch App
//
//  Created by: Grant Perry on 5/25/23.

//			Modified: Wednesday February 28, 2024 at 9:01:26 AM


import SwiftUI

let APP_NAME 		= "BigMetric"
let APP_VERSION 	= "3.4a RhiNO-M0nkEY-FarT"
let MOD_DATE 		= "Modified: 3/9/24 | 5:28PM"

@main
struct BigMetric_Watch_AppApp: App {
   @Environment(\.scenePhase) var scenePhase
	@State var distanceTracker: DistanceTracker = DistanceTracker()
	@State var workoutManager: WorkoutManager = WorkoutManager(distanceTracker: DistanceTracker(),
															   weatherKitManager: WeatherKitManager(distanceTracker: DistanceTracker()),
															   geoCodeHelper: GeoCodeHelper(distanceTracker: DistanceTracker()))
	@State var weatherKitManager: WeatherKitManager = WeatherKitManager(distanceTracker: DistanceTracker())
	@State var geoCodeHelper: GeoCodeHelper = GeoCodeHelper(distanceTracker: DistanceTracker())
   @State private var distanceTrackerInitialized = false
   @State private var selectedTab = 2

   var body: some Scene {
      WindowGroup {
         TabView(selection: $selectedTab) {

				endWorkout(distanceTracker: distanceTracker,
							  workoutManager: workoutManager,
							  selectedTab: $selectedTab) // when end workout is finished
               .tabItem { Image(systemName: "circle.fill") }
               .tag(0)

				howFarGPS(distanceTracker: distanceTracker,
							 workoutManager: workoutManager)
               .tabItem { Image(systemName: "circle.fill") }
               .tag(2)

				debugScreen(distanceTracker: distanceTracker,
								workoutManager: workoutManager,
								weatherKitManager: weatherKitManager,
								geoCodeHelper: geoCodeHelper)
               .tabItem { Image(systemName: "circle.fill") }
               .tag(3)

				summary(distanceTracker: distanceTracker,
						  workoutManager: workoutManager,
						  selectedTab: $selectedTab)
					.tag(4)

				AltitudeView(distanceTracker: distanceTracker)
					.tabItem { Image(systemName: "circle.fill") }
					.tag(5)

				CompassView(workoutManager: workoutManager,
								heading: 0.0, routeHeading: 0.0)
               .tabItem { Image(systemName: "circle.fill") }
               .tag(6)

				showHeartBeat(distanceTracker: distanceTracker)
					.tabItem { Image(systemName: "circle.fill") }
					.tag(7)
         }
         .onAppear {
            self.selectedTab = 2
            workoutManager.requestHKAuth()
         }
         .tabViewStyle(PageTabViewStyle())
      }
   }
}


