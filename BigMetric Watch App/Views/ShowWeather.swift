//
//  ShowWeather.swift
//  howFar Watch App
//
//  Created by Grant Perry on 4/16/23.
//
import Foundation
import SwiftUI
import Combine

struct ShowWeather: View {
//   @EnvironmentObject var distanceTracker: DistanceTracker
//   @EnvironmentObject var workoutManager: WorkoutManager
	var distanceTracker: DistanceTracker
   var weatherKitManager: WeatherKitManager
	var geoCodeHelper: GeoCodeHelper
	var workoutManager: WorkoutManager?

   @State var address: String = "Loading address..."
   private var gradient: Gradient {
      Gradient(colors: [.blue, .red])
   }

   var body: some View {
      VStack(alignment: .leading) {
         // Temperature and Weather Symbol
         HStack {
            VStack {
               Gauge(value: Double(weatherKitManager.tempVar) ?? 0, in: (Double(weatherKitManager.lowTempVar) ?? 0)...(Double(weatherKitManager.highTempVar) ?? 0)) {
                  Text("Temp")
               } currentValueLabel: {
                  Text(weatherKitManager.tempVar)
               }
               .gaugeStyle(.accessoryCircular)
               .tint(gradient)
               .frame(width: 50, height: 50)
               .scaleEffect(0.95)
               .font(.system(size:10))
               .foregroundColor(.white)
               .padding(.top, -4)
               .padding(.bottom, 5)
            }
            //.buttonStyle(PlainButtonStyle())
            .background(Color.clear)
            VStack {
               HStack {
                  Image(systemName: weatherKitManager.symbolVar)
                     .font(.system(size:20))
                     .foregroundColor(.white)
                  Text("\(weatherKitManager.lowTempVar)/\(weatherKitManager.highTempVar)")
                  Text(address)
                     .onAppear {

                        geoCodeHelper.getCityNameFromCoordinates(distanceTracker.currentCoords.latitude, distanceTracker.currentCoords.longitude) { result in
							address = result?.locality ?? "loading"
							workoutManager?.thisAddress = address // push workoutManager.thisAddress for buildRouteMetadata checker
                        }
                     }
                  
               }
//               HStack {
//                  Text(gpDateStuff.getDayName(1))
//               }
//               HStack {
//                  Text(gpDateStuff.getDayName(2))
//               }
            }

            .font(.system(size:13))
            .foregroundColor(.gpBlue)

            Spacer()
         }

         .background(Color.clear)

         // Wind Speed and SF Symbol
         HStack {
            Image(systemName: "wind")
            Text("\(weatherKitManager.windSpeedVar, specifier: "%.1f") mph")
            Spacer()
         }

         // Wind Direction and SF Symbol
         HStack {
            Image(systemName: "location.north.fill")
               .rotationEffect(.degrees(CardinalDirection(rawValue: weatherKitManager.windDirectionVar)?.degrees ?? 0))

            Text(weatherKitManager.windDirectionVar)
            Spacer()
         }
      }
      .font(.footnote)
	  .onAppear {
		  Task {
			  do {
				  try await weatherKitManager.getWeather(for: distanceTracker.currentCoords)
			  } catch {
				  // Handle potential errors here
				  print("Error during onAppear: \(error.localizedDescription)")
			  }
		  }
	  }

   }
}

//struct ShowWeather_Previews: PreviewProvider {
//   static var previews: some View {
//      ShowWeather()
//         .environmentObject(DistanceTracker())
//         .environmentObject(WorkoutManager())
//         .environmentObject(WeatherKitManager())
//         .environmentObject(GeoCodeHelper(distanceTracker: DistanceTracker()))
//   }
//}




