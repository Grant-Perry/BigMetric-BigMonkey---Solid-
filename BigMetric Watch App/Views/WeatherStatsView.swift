//
//  WeatherStatsView.swift
//  howFar Watch App
//
//  Created by Grant Perry on 4/23/23
//		Modified: Thursday January 11, 2024 at 9:33:06 AM
//

import Foundation
import WeatherKit
import CoreLocation
import SwiftUI


struct WeatherStatsView: View {
	@Bindable var weatherKitManager: WeatherKitManager
	@Bindable var distanceTracker: DistanceTracker
	@Bindable var geoCodeHelper: GeoCodeHelper

	@Binding var showWeatherStatsView: Bool
	@State private var address = ""
	var nextHrTemp: Double { Double(weatherKitManager.tempHour) ?? 0 }
	var thisHrtemp: Double { Double(weatherKitManager.tempVar) ?? 0 }
	var nextHrTempColor: Color { PrecipChanceColor.from(chance: Int(nextHrTemp)) }
	var thisHrTempColor: Color { PrecipChanceColor.from(chance: Int(thisHrtemp)) }
	var precipChance: Double { min(weatherKitManager.precipForecast * 100, 100) }
	var precipColor: Color { PrecipChanceColor.from(chance: Int(precipChance)) }

	var body: some View {
		ScrollView {
			VStack {
				HStack {
					Button(action: {
						showWeatherStatsView = false
					}) {
						Text("") // Close
					}
					.font(.system(size: 9)) // Make the text smaller
					.background(Color.clear) // Set the background to clear
					.buttonStyle(PlainButtonStyle())
					.cornerRadius(5)
					.padding(.trailing)
				}

				Group {
					// current temp & conditions
					Text("\(weatherKitManager.tempVar)°")
						.font(.system(size: 50, weight: .bold))
						.foregroundColor(thisHrTempColor)

					Image(systemName: weatherKitManager.symbolVar)
						.font(.system(size: 45))
						.foregroundColor(.white)
				}
				.bold()
				Spacer()
				Group {
					HStack {
						Text("\(distanceTracker.hotColdFirst ? weatherKitManager.highTempVar : weatherKitManager.lowTempVar)°")
							.foregroundColor(TemperatureColor.from(temperature: Double(distanceTracker.hotColdFirst ? weatherKitManager.highTempVar : weatherKitManager.lowTempVar)!))
							.foregroundColor(.gpBlue)
						Text(" / ")
							.foregroundColor(.white)
						Text("\(distanceTracker.hotColdFirst ? weatherKitManager.lowTempVar : weatherKitManager.highTempVar)°")
							.foregroundColor(TemperatureColor.from(temperature: Double(distanceTracker.hotColdFirst ? weatherKitManager.lowTempVar : weatherKitManager.highTempVar)!))
					}
					.font(.system(size: 13))

					Image(systemName: weatherKitManager.symbolHourly)
					HStack {
						Text("Next Hr Rain:")
							.foregroundColor(.white)

						Text("\(gpNumFormat.formatNumber(precipChance, 0))%")
							.foregroundColor(precipColor)
					}
					HStack {
						Text("Next Hr Temp:")
							.foregroundColor(.white)

						Text(gpNumFormat.formatNumber(nextHrTemp, 0))
							.foregroundColor(nextHrTempColor)
					}
					//               }
				}
				.font(.system(size: 12))
			}

			Text(address)
				.onAppear {
					geoCodeHelper.getCityNameFromCoordinates(distanceTracker.currentCoords.latitude,
															  distanceTracker.currentCoords.longitude) { result in
						address = result?.locality ?? "loading"
					}
				}
				.font(.footnote)
				.foregroundColor(.gpPurple)
				.bold()

			Divider()
				.padding(.vertical)
			/*
			 -------- create the list of daily weather view
			 */
			VStack(alignment: .leading, spacing: 10) {
				ForEach(Array(weatherKitManager.weekForecast.enumerated()), id: \.element.id) { index, forecast in
					dailyView(index, forecast)
					Divider()
				}
			}
		}
	}

	//   func dailyView(_ index: Int, _ forecast: WeatherKitManager.Forecasts) -> HStack<TupleView<(Group<TupleView<(Text, Spacer, some View)>>, Spacer, some View)>> {
	//      return HStack {
	func dailyView(_ index: Int, _ forecast: WeatherKitManager.Forecasts) -> some View {
		HStack {
			Group {
				Text("\(gpDateStuff.getDayName(daysFromToday: index + 1)):")
					.font(.system(size: 20))
					.bold()
					.foregroundColor(.white)
				Spacer()
				Image(systemName: forecast.symbolName)
					.foregroundColor(.white)
					.bold()
			}
			Spacer()
//MARK: - the conditions & temp value just under the miles
			let mainTemp = distanceTracker.hotColdFirst ? forecast.maxTemp : forecast.minTemp
			let secondTemp = distanceTracker.hotColdFirst ? forecast.minTemp : forecast.maxTemp
			let mainTemperatureColor = TemperatureColor.from(temperature: Double(mainTemp)!)
			let secondaryTemperatureColor = TemperatureColor.from(temperature: Double(secondTemp)!)
			HStack {
				Text("\(distanceTracker.hotColdFirst ? mainTemp : secondTemp)°")
					.foregroundColor(distanceTracker.hotColdFirst ? mainTemperatureColor : secondaryTemperatureColor)
					.font(.system(size: 17))
				Text("/")
					.foregroundColor(.white)
				Text("\(				Text("\(distanceTracker.hotColdFirst ? secondTemp : mainTemp)°"))°")
					.foregroundColor(distanceTracker.hotColdFirst ? secondaryTemperatureColor : mainTemperatureColor)

					.font(.system(size: 17))
			}

			.font(.system(size: 20))
			.bold()
		}
	}
}

