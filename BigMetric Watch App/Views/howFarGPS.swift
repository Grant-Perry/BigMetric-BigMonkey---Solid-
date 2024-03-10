//  howFarGPS.swift
//  howFar Watch App
//
//  Created by: Grant Perry on 1/21/23.
//    Modified: Tuesday November 28, 2023 at 7:39:49 AM

import SwiftUI
import CoreMotion
import CoreLocation
import HealthKit
import WatchConnectivity

struct howFarGPS: View {
#if os(watchOS)
	@State var screenBounds = WKInterfaceDevice.current().screenBounds
#else
	@State var screenBounds = UIScreen.main.bounds
#endif
	var distanceTracker: DistanceTracker
	var workoutManager: WorkoutManager
	@Environment(\.colorScheme) var colorScheme
	@State var debug								= false
	@State var resetDist							= false
	@State var isAuthorized						= false
	@State var isHealthUpdate					= false
	@State var debugStr							= ""
	@State var gpsLoc								= "GPS"
	@State var selectedDistance				= "Miles"
	@State var gradStopColor					= Color(#colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1))
	//// ------------- Main Button Co		lors --------------------
	@State var bgYardsStopTop					= Color(#colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1))
	@State var bgYardsStopBottom				= Color(#colorLiteral(red: 1, green: 0.1271572973, blue: 0.969772532, alpha: 1))
	@State var bgYardsStartTop					= Color(#colorLiteral(red: 1, green: 0.5212053061, blue: 1, alpha: 1))
	@State var bgYardsStartBottom			= Color(#colorLiteral(red: 1, green: 0.1271572973, blue: 0.969772532, alpha: 1))
	@State var bgMilesStopTop					= Color(#colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1))
	@State var bgMilesStopBottom				= Color(#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1))
	@State var bgMilesStartTop					= Color(#colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1))
	@State var bgMilesStartBottom			= Color(#colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1))
	//// -------------- End Button Co		lors  --------------------
	@State var timeOut							= Color(#colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1))
	@State var backColor							= Color(#colorLiteral(red: 0.8699219823, green: 0.9528884292, blue: 0.8191569448, alpha: 1))
	@State var isHealthUpdateOn				= Color(#colorLiteral(red: 0.2760013003, green: 0.4030833564, blue: 0.8549019694, alpha: 1))
	@State var isUpdatingOn						= Color(#colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1))
	@State var isUpdatingOnStop				= Color(#colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1))
	@State var isUpdatingOff					= Color(#colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1))
	@State var isUpdatingOffStop				= Color(#colorLiteral(red: 0.9260191787, green: 0.1247814497, blue: 0.4070666561, alpha: 1))
	@State var isRecordingColor				= Color(#colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1))
	@State var distanceHowFarGPS: Double 	= 0
	var timePadding						= 70.0
	var width								= 65.0
	var height								= 25.0
	var isUp: Bool {
		return distanceTracker.isUpdating
	}
	var isRecording: Bool {
		return distanceTracker.weIsRecording
	}


	var body: some View {
		VStack(alignment: .center, spacing:0) {
			VStack(spacing: 0) {
				VStack { // top spacer
				}
				.frame(height: 70)
				VStack(alignment: .center, spacing: 0) {

					ButtonView(stateBtnColor: isRecording ? (isUp ? isRecordingColor : .white) : .black,
								  startColor: !isRecording ? (distanceTracker.yardsOrMiles ? bgMilesStopTop : bgYardsStopTop) : (distanceTracker.yardsOrMiles ? bgMilesStartTop : bgYardsStartTop),
								  endColor: !isRecording ? (distanceTracker.yardsOrMiles ? bgMilesStopBottom : bgYardsStopBottom) : (distanceTracker.yardsOrMiles ? bgMilesStartBottom : bgYardsStartBottom),
								  isUp: self.isUp,
								  screenBounds: self.screenBounds)
 // MARK: It all starts here - the button
					.overlay(
						VStack {
							DoubleClickButton(action: {
								// check to be certain we have garnered an accurate initial location
								//                        if !distanceTracker.isInitialLocationObtained {
								if !isRecording {
									if distanceTracker.isBeep {
										PlayHaptic.tap(PlayHaptic.start)
									}

									let wmState = workoutManager.workoutSessionState
									if wmState == .notStarted || wmState == .ended  {
										// start/restart the routeManger and initialize startStepCnt & lastLocation

										// bleach the properties
										workoutManager.resetWorkout()
										distanceTracker.cleanVars 	= true
										// get the initial existing step count
										distanceTracker.queryStepCount { steps in
											if let steps = steps {
												distanceTracker.startStepCnt = steps
												print("Number of steps inside wmState: \(steps)")
											} else {
												print("Error retrieving step count.") } }
										distanceTracker.lastLocation = nil  // reset to be certain there is nothing cached
										distanceTracker.holdCLLocations = []
										workoutManager.startWorkout(workoutType: .walking) // start the HKWorkoutLive
									} else {
										workoutManager.togglePause()
									}
									distanceTracker.toggleWeIsRecording(true)
									distanceTracker.showStartText = false // used for the Start text on the button
																					  // Request the current location
									distanceTracker.startUpdates()
								} else {
									if distanceTracker.isBeep {
										PlayHaptic.tap(PlayHaptic.stop)
									}
									workoutManager.togglePause()
									distanceTracker.toggleWeIsRecording(false)
									_ = distanceTracker.stopUpdates(false) // stop but do not refresh properties
								}
							})
							{
							// MARK: - Distance text
							InsideButtonTextView(distanceTracker: distanceTracker)
							}
						}
							.sheet(isPresented: Binding(get: { distanceTracker.ShowEstablishGPSScreen },
																 set: { _ in })) {
																	 ZStack {
																		 LocationProgressView(message: "GPS Position")
																	 }
																 }
							.tint(Color(.clear))
							.foregroundColor(.white)
					)
					.padding(.top, -35)
					// MARK: - Time Display
					ShowTimeOrSpeed(distanceTracker: distanceTracker, 
										 workoutManager: workoutManager)
				}

				VStack {
					HStack(alignment: .center, spacing:7) {
						// MARK: - Reset Button
						HStack {
							DoubleClickButton(action: {
								distanceTracker.showStartText 	= true
								_ = distanceTracker.stopUpdates(true)
								workoutManager.resetWorkout()
							}) {
								Text("+/-")
									.font(.footnote)
									.fontWeight(.medium)
									.foregroundColor(.white)
									.cornerRadius(10)
							}
							.frame(width: 43, height: height, alignment: .center)
							.background(LinearGradient(gradient: Gradient(colors: [.blue, gradStopColor]),
																startPoint: .bottomLeading,
																endPoint: .topLeading))
							.cornerRadius(15)
						}
						HStack {
							DoubleClickButton(action: {
								distanceTracker.showStartText 	= true
								distanceTracker.yardsOrMiles 		= false
								distanceTracker.toggleYMBool(false)
							}) {
								Text("Yards")
									.font(.footnote)
									.foregroundColor(.white)
									.cornerRadius(10)
							}
							.frame(width: width, height: height, alignment: .center)
							.background(LinearGradient(gradient: Gradient(colors: [bgYardsStopTop, bgYardsStopBottom]),
																startPoint: .bottomLeading,
																endPoint: .topLeading))
							.cornerRadius(15)
							.overlay(
								RoundedRectangle(cornerRadius: 15)
									.stroke(distanceTracker.yardsOrMiles ? .black : .white, lineWidth: 3)
							)
						}

						HStack {
							DoubleClickButton(action: {
								distanceTracker.isSpeed = false
								distanceTracker.yardsOrMiles = true
								distanceTracker.showStartText = true
								//              self.isRecording = false
								distanceTracker.toggleYMBool(true)
							}) {

								Text("Miles")
									.font(.footnote)
									.foregroundColor(.white)
									.cornerRadius(10)
							}
							.frame(width: width, height: height, alignment: .center)
							.background(LinearGradient(gradient: Gradient(colors: [
								distanceTracker.yardsOrMiles ? (!isRecording ? bgMilesStopTop : bgMilesStartTop) : bgMilesStopTop,
								distanceTracker.yardsOrMiles ? (!isRecording ? bgMilesStopBottom : bgMilesStartBottom) : bgMilesStopBottom
							]), startPoint: .bottomLeading, endPoint: .topLeading))
							.cornerRadius(15)
							.overlay(
								RoundedRectangle(cornerRadius: 15)
									.stroke(!distanceTracker.yardsOrMiles ? .black : .white, lineWidth: 3)
							)
						}
					}
					.frame(width: (screenBounds.width / 0.5), height: 100)
				}
				.padding(.top, -30)
			}
			// MARK: - isUpdating beacon
			ZStack {
				HStack {
					HStack {
						Circle()
							.fill(LinearGradient(gradient: Gradient(colors: [isUp ? isUpdatingOn :
																								(isHealthUpdate ? isHealthUpdateOn : isUpdatingOff),
																							 isUp ? isUpdatingOnStop : isUpdatingOffStop]),
														startPoint: .topLeading,
														endPoint: .bottomTrailing))
							.frame(width: 10, height: 10)
							.offset(x: 98, y: (-screenBounds.height / 2))
					}

					Spacer()
						.frame(width: 15)
					// MARK: - GPSIcon beacon
					HStack {
						GPSIconView(accuracy: Int(distanceTracker.GPSAccuracy), size: 17.0)
							.frame(width: 25, height: 40)
							.offset(x: 75, y: (-screenBounds.height / 2  - 20))
					}
				}
				.frame(height:39)
				.background(.black)
			}

		}
		.preferredColorScheme(.dark)
	}

	func updateDebugStr(_ var1: Bool, _ var2: Bool) {
		debugStr = "YM: \(String(var1)) - isRec: \(String(var2))"
	}
}

