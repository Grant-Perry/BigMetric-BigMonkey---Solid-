//
//  summary.swift
//  howFar Watch App
//
//  Created by Grant Perry on 3/21/23.
//
//  Modified: Sunday December 31, 2023 at 11:22:00 AM

import SwiftUI
import Combine
import HealthKit

struct summary: View {
	@Bindable var distanceTracker: DistanceTracker
	@Bindable var workoutManager:WorkoutManager
	@Binding 				var	selectedTab:		Int
//	@State 			 		var	finalSteps: 		Int = 0
	@State 			 		var	durationFormatter: DateComponentsFormatter = {
		let formatter				= DateComponentsFormatter()
		formatter.allowedUnits 	= [.hour, .minute, .second]
		formatter.zeroFormattingBehavior = .pad
		return formatter
	}()
	var showStatus = false // this is for debugging. True will display the loading modal until workout finished

	var body: some View {
		ZStack {
//			if workoutManager.workout == nil {
			if showStatus {
				VStack(spacing: 20) {
					ProgressView("Saving Workout")
						.progressViewStyle(CircularProgressViewStyle())
					Spacer()
				}
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.foregroundColor(.teal)
				.background(Color.black)
				.navigationBarHidden(true)


			} else {
				ScrollView(.vertical) {
					VStack(alignment: .leading) {
						SummaryMetricView(
							title: "Distance:",
							
							value: gpNumFormat.formatNumber(distanceTracker.distance > 0 ? distanceTracker.distance : distanceTracker.finalDist , 4))
						.accentColor(.gpPink)

						SummaryMetricView(
							title: "Total Time:",
							value: distanceTracker.formattedTimeString)
						.accentColor(.gpBlue)

						Group {
							SummaryMetricView(
								title: "Total Steps:",
								value: distanceTracker.workoutStepCount > 0 ? gpNumFormat.formatNumber(Double(distanceTracker.workoutStepCount), 0) : "0")
							.accentColor(.gpGreen)
							.lineLimit(1)
							.minimumScaleFactor(0.5)
							.scaledToFit()
						}

						SummaryMetricView(
							title: "Total Energy:",
							value: Measurement(
								value: workoutManager.workout?.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
								unit: UnitEnergy.kilocalories
							).formatted(
								.measurement(
									width: .abbreviated,
									usage: .workout,
									numberFormatStyle:
										FloatingPointFormatStyle
										.number
										.precision(.fractionLength(0))
								)
							)
						)
						.accentColor(.pink)

// compiler hates Avg. Heart Rate section
//						SummaryMetricView(
//							title: "Avg. Heart Rate:",
//							value: gpNumFormat.formatNumber(distanceTracker.calculateAverageHeartRate(bleach: true), 0)
////							value: gpNumFormat.formatNumber(distanceTracker.heartRate, 0)
//							+
//							" bpm"
//						)
//						.accentColor(.gpPink)
						SummaryMetricView(
							title: "App Version: ",
							value: APP_VERSION)
						.accentColor(.gpPink)
						// Put a version text here?

						Text("Activity Rings")
						ActivityRingsView(healthStore: HKHealthStore())
							.frame(width: 50, height: 50)

						Button("Done") {
							self.selectedTab = 2
						}
					}
					.scenePadding()
				}
				.navigationTitle("Summary")
				.navigationBarTitleDisplayMode(.inline)
			}
		}
	}
}

struct SummaryMetricView: View {
//	@EnvironmentObject var distanceTracker: DistanceTracker
//	@EnvironmentObject var workoutManager:WorkoutManager

	var title: String
	var value: String

	var body: some View {
		Group {
			Text(title)
			Text(value)
				.font(
					.system(.title2, design: .rounded)
					.lowercaseSmallCaps()
				)
				.foregroundColor(.accentColor)
			
			if title == "App Version: " {
				Text("\(MOD_DATE)")
					.font(.system(size: 11))
					.foregroundColor(Color.gpBlue)
			}
		}
		Divider()
	}
}
