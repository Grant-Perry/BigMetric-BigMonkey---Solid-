//
//  endWorkout.swift
//  howFar Watch App
//
//  Created by: Grant Perry on 2/9/23.
//    Modified: Friday November 3, 2023 at 2:07:46 PM
//

import SwiftUI
import CoreMotion
import CoreLocation
import HealthKit
import UIKit

struct endWorkout: View {
	@Environment(\.colorScheme) var colorScheme
	@Bindable var distanceTracker: DistanceTracker
	@Bindable var workoutManager: WorkoutManager
	@Binding var selectedTab: Int


	//   @State var mySelectedTab = 6

	var screenBounds = WKInterfaceDevice.current().screenBounds
	@State var yardsOrMiles = false
	@State var isStopping = true // state of running / ending workout
	@State private var isRecording	= true
	@State var timeOut = Color(#colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1))
	@State var headerBGColor = Color(#colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1))
	@State var headerBGColor2 =  Color(#colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1))
	@State var isStoppingColor = Color(#colorLiteral(red: 1, green: 0.5409764051, blue: 0.8473142982, alpha: 1))

	var body: some View {
		VStack {
			ButtonView(stateBtnColor: Color(.white),
						  startColor: headerBGColor,
						  endColor: isStoppingColor,
						  isUp: !self.isStopping)
			.overlay(
				VStack {
					Button(action: {
						isStopping = false
						// PlayHaptic.tap(PlayHaptic.start)

						Task {
//							print("STOPPING WORKOUT NOW - button just pressed")
							await workoutManager.endWorkoutbuilder() // Adjusted to call async function
							_ = distanceTracker.stopUpdates(false) // Assuming this is synchronous; if not, wrap in await as well.
							distanceTracker.cleanVars = true // didSet will handle reset

							// Move UI updates back to the main thread if stopUpdates or cleanVars are async and might change UI state.
							DispatchQueue.main.async {
								isStopping = true
								// PlayHaptic.tap(PlayHaptic.stop)
								self.selectedTab = 4 // show summary
							}
						}
					}) {
						Text(isStopping ? "End Workout" : "Writing Workout")
							.padding(.top, -20)
					}

				}
			)
			//         TimeView()
		}
	}
}

extension View {
	func modTimeHead(_ timeOut: Color) -> some View {
		self
			.frame(maxWidth: .infinity, alignment: .center)
			.padding(.top, 8)
			.font(.caption2)
			.foregroundColor(timeOut)
			.background(Color.white.opacity(0.15))
			.cornerRadius(10)
	}

	func modTimeVal(_ headText: Color) -> some View {
		self
			.frame(maxWidth: .infinity, alignment: .center)
			.baselineOffset(16)
			.foregroundColor(headText)
			.font(.caption2)
	}
}
