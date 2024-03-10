//   CityCoords.swift
//   BigMetric
//
//   Created by: Grant Perry on 2/7/24 at 10:43 AM
//     Modified: 
//
//  Copyright © 2024 Delicious Studios, LLC. - Grant Perry
//

import SwiftUI

struct CityCoords {
	var cityName: String
	var longitude: Double
	var latitude: Double
}

let cityCoords: [String: CityCoords] = [
	"New York": CityCoords(cityName: "New York", longitude: -74.005973, latitude: 40.712776),
	"Los Angeles": CityCoords(cityName: "Los Angeles", longitude: -118.243685, latitude: 34.052234),
	"Chicago": CityCoords(cityName: "Chicago", longitude: -87.629798, latitude: 41.878113),
	"Houston": CityCoords(cityName: "Houston", longitude: -95.369803, latitude: 29.760427),
	"Phoenix": CityCoords(cityName: "Phoenix", longitude: -112.074037, latitude: 33.448377),
	"Philadelphia": CityCoords(cityName: "Philadelphia", longitude: -75.165222, latitude: 39.952583),
	"San Antonio": CityCoords(cityName: "San Antonio", longitude: -98.493628, latitude: 29.424122),
	"San Diego": CityCoords(cityName: "San Diego", longitude: -117.161084, latitude: 32.715738),
	"Dallas": CityCoords(cityName: "Dallas", longitude: -96.7970, latitude: 32.7767),
	"San Jose": CityCoords(cityName: "San Jose", longitude: -121.886329, latitude: 37.338208),
	"Austin": CityCoords(cityName: "Austin", longitude: -97.743061, latitude: 30.267153),
	"Jacksonville": CityCoords(cityName: "Jacksonville", longitude: -81.655651, latitude: 30.332184),
	"Fort Worth": CityCoords(cityName: "Fort Worth", longitude: -97.330766, latitude: 32.755488),
	"Columbus": CityCoords(cityName: "Columbus", longitude: -82.998794, latitude: 39.961176),
	"Charlotte": CityCoords(cityName: "Charlotte", longitude: -80.843127, latitude: 35.227087),
	"San Francisco": CityCoords(cityName: "San Francisco", longitude: -122.419416, latitude: 37.774929),
	"Indianapolis": CityCoords(cityName: "Indianapolis", longitude: -86.158068, latitude: 39.768403),
	"Seattle": CityCoords(cityName: "Seattle", longitude: -122.332071, latitude: 47.606209),
	"Denver": CityCoords(cityName: "Denver", longitude: -104.990251, latitude: 39.739236),
	"Washington": CityCoords(cityName: "Washington D.C.", longitude: -77.036871, latitude: 38.907192),
	"Boston": CityCoords(cityName: "Boston", longitude: -71.058880, latitude: 42.360082),
	"El Paso": CityCoords(cityName: "El Paso", longitude: -106.485022, latitude: 31.761878),
	"Detroit": CityCoords(cityName: "Detroit", longitude: -83.045754, latitude: 42.331427),
	"Nashville": CityCoords(cityName: "Nashville", longitude: -86.781602, latitude: 36.162664),
	"Memphis": CityCoords(cityName: "Memphis", longitude: -90.048980, latitude: 35.149534),
	"Portland": CityCoords(cityName: "Portland", longitude: -122.676482, latitude: 45.523062),
	"Las Vegas": CityCoords(cityName: "Las Vegas", longitude: -115.139830, latitude: 36.169941),
	"Louisville": CityCoords(cityName: "Louisville", longitude: -85.758456, latitude: 38.252665),
	"Baltimore": CityCoords(cityName: "Baltimore", longitude: -76.612189, latitude: 39.290385),
	"Milwaukee": CityCoords(cityName: "Milwaukee", longitude: -87.906474, latitude: 43.038902),
	"Albuquerque": CityCoords(cityName: "Albuquerque", longitude: -106.650422, latitude: 35.084386),
	"Tucson": CityCoords(cityName: "Tucson", longitude: -110.974711, latitude: 32.222607),
	"Fresno": CityCoords(cityName: "Fresno", longitude: -119.787125, latitude: 36.737798),
	"Sacramento": CityCoords(cityName: "Sacramento", longitude: -121.494400, latitude: 38.581572),
	"Kansas City": CityCoords(cityName: "Kansas City", longitude: -94.578567, latitude: 39.099727),
	"Long Beach": CityCoords(cityName: "Long Beach", longitude: -118.193740, latitude: 33.770050),
	"Mesa": CityCoords(cityName: "Mesa", longitude: -111.831472, latitude: 33.415184),
	"Atlanta": CityCoords(cityName: "Atlanta", longitude: -84.387982, latitude: 33.748995),
	"Colorado Springs": CityCoords(cityName: "Colorado Springs", longitude: -104.821363, latitude: 38.833882),
	"Virginia Beach": CityCoords(cityName: "Virginia Beach", longitude: -75.978835, latitude: 36.852926),
	"Raleigh": CityCoords(cityName: "Raleigh", longitude: -78.638179, latitude: 35.779590),
	"Omaha": CityCoords(cityName: "Omaha", longitude: -95.934503, latitude: 41.256537),
	"Miami": CityCoords(cityName: "Miami", longitude: -80.191790, latitude: 25.761680),
	"Oakland": CityCoords(cityName: "Oakland", longitude: -122.271114, latitude: 37.804364),
	"Minneapolis": CityCoords(cityName: "Minneapolis", longitude: -93.265011, latitude: 44.977753)
]

// Combine with the existing cityCoords
//let updatedCityCoords = combinedCityCoords.merging(moreCityCoords) { (current, _) in current }
