//
//  showAllWeather.swift
//  howFar Watch App
//
//  Created by Grant Perry on 4/19/23.
//	Modified: Tuesday January 9, 2024 at 9:47:18 PM

import SwiftUI


struct showAllWeather: View {
var weatherKitManager: WeatherKitManager
var geoCodeHelper: GeoCodeHelper
var distanceTracker: DistanceTracker
	

   @State private var address = ""
   private var gradient: Gradient {
      Gradient(colors: [.gpBlue, .gpRed])
   }

   var body: some View {
      todaysWeather()
   }


   func todaysWeather() -> HStack<TupleView<(some View, some View, Spacer)>> {
      return HStack(alignment: .center) {
			Gauge(
				value: Double(weatherKitManager.tempVar) ?? 0,
				in: (Double(weatherKitManager.lowTempVar) ?? 0)...(Double(weatherKitManager.highTempVar) ?? 0)
			) {
				Text("Temp")
			} currentValueLabel: {
				Text(weatherKitManager.tempVar) // Wrap it in a Text view
			}

         .gaugeStyle(.accessoryCircular)
         .tint(gradient)
         .frame(width: 50, height: 50)
         .scaleEffect(0.95)
         .font(.system(size:10))
         .foregroundColor(.white)
         .padding(.top, -4)
         .padding(.bottom, 5)
         VStack(alignment: .leading, spacing: 2) {
				HStack(alignment: .center, spacing: 2) {
					let primaryTemp = distanceTracker.hotColdFirst ? weatherKitManager.highTempVar : weatherKitManager.lowTempVar
					let secondaryTemp = distanceTracker.hotColdFirst ? weatherKitManager.lowTempVar : weatherKitManager.highTempVar
					let fontSize:CGFloat = 16.0

					Image(systemName: weatherKitManager.symbolVar)
						.font(.system(size: fontSize))
						.foregroundColor(.white)



					Text("\(primaryTemp)°")
						.font(.system(size: fontSize))
						.foregroundColor(TemperatureColor.from(temperature: Double(primaryTemp) ?? 0))

					Text("/")
						.font(.system(size: fontSize))
						.foregroundColor(.white)

					Text("\(secondaryTemp)°")
						.font(.system(size: fontSize))
						.foregroundColor(TemperatureColor.from(temperature: Double(secondaryTemp) ?? 0))
				}

            Text(address)
               .onAppear {
                  geoCodeHelper.getCityNameFromCoordinates(distanceTracker.currentCoords.latitude,
                                                  distanceTracker.currentCoords.longitude) { result in
					  address = result?.locality ?? "loading"
                  }
               }

               .font(.system(size: 12))
               .foregroundColor(.white)
         }
         .padding(.leading, 10)
         Spacer()
      }
   }
}
//
//struct showAllWeather_Previews: PreviewProvider {
//   static var previews: some View {
//      let weatherKitManager = WeatherKitManager()
//      let geoCodeHelper = GeoCodeHelper()
//      let distanceTracker = DistanceTracker()
//      return showAllWeather()
//         .environmentObject(weatherKitManager)
//         .environmentObject(geoCodeHelper)
//         .environmentObject(distanceTracker)
//   }
//}
