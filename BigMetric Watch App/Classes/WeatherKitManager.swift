//
//  WeatherKitManager.swift
//  howFar Watch App
//
//  Created: Grant Perry on 4/16/23.
// Modified: Wednesday March 6, 2024 at 12:43:06 AM
//

import SwiftUI
import Observation
import WeatherKit
import CoreLocation

@Observable
/// ``WeatherKitManager``
/// Manages weather data retrieval and processing for a given location using WeatherService.
/// This class encapsulates functionality for fetching daily and hourly weather forecasts, converting coordinates,
/// and storing weather-related data such as temperature, wind speed, and precipitation forecasts.
///
/// Properties include references to `DistanceTracker` for location data, weather forecasts, and UI-related variables
/// to manage the display of weather information and error states.
class WeatherKitManager: NSObject {


	// MARK: - Constants
	let distanceTracker: DistanceTracker // Reference to a DistanceTracker instance for location-related data.
	let sharedService = WeatherService.shared // Shared instance of WeatherService for accessing weather APIs.
	let weatherService = WeatherService() // Instance of WeatherService for fetching weather data.

	// MARK: - Variables: Booleans
	var isErrorAlert: Bool = false // Flag to indicate whether an error alert should be displayed.

	// MARK: - Variables: Doubles
	var latitude: Double = 0 // Latitude of the location for which weather data is being fetched.
	var longitude: Double = 0 // Longitude of the location for which weather data is being fetched.
	var precipForecast: Double = 0 // Precipitation forecast value.
	var precipForecast2: Double = 0 // Additional precipitation forecast value for extended data processing.
	var precipForecastAmount: Double = 0 // Amount of precipitation forecasted.
	var windSpeedVar: Double = 0 // Variable to store wind speed data from weather forecast.

	// MARK: - Variables: Forecasts
	var dailyForecast: Forecast<DayWeather>? // Container for daily weather forecast data.
	var hourlyForecast: Forecast<HourWeather>? // Container for hourly weather forecast data.
	var weekForecast: [Forecasts] = [] // Array of forecasts, structured for weekly display.

	// MARK: - Variables: Strings
	var highTempVar: String = "" // String representing the high temperature forecast.
	var locationName: String = "" // Name of the location for which weather data is being fetched.
	var lowTempVar: String = "" // String representing the low temperature forecast.
	var symbolHourly: String = "" // Symbol representing the hourly weather condition.
	var symbolVar: String = "xmark" // Symbol representing the current weather condition.
	var tempHour: String = "" // String representing the hourly temperature.
	var tempVar: String = "" // String representing the current temperature.
	var windDirectionVar: String = "" // String representing the wind direction.

	// MARK: - Variables: Dates
	var date: Date = .now // Current date, used for weather data retrieval.

	// MARK: - Computed Properties
	var cLocation: CLLocation { // Computed property to convert latitude and longitude into a CLLocation object.
		CLLocation(latitude: latitude, longitude: longitude)
	}

	internal init(distanceTracker: DistanceTracker, isErrorAlert: Bool = false, latitude: Double = 0, longitude: Double = 0, precipForecast: Double = 0, precipForecast2: Double = 0, precipForecastAmount: Double = 0, windSpeedVar: Double = 0, dailyForecast: Forecast<DayWeather>? = nil, hourlyForecast: Forecast<HourWeather>? = nil, weekForecast: [Forecasts] = [], highTempVar: String = "", locationName: String = "", lowTempVar: String = "", symbolHourly: String = "", symbolVar: String = "xmark", tempHour: String = "", tempVar: String = "", windDirectionVar: String = "", date: Date = .now) {
		self.distanceTracker = distanceTracker
		self.isErrorAlert = isErrorAlert
		self.latitude = latitude
		self.longitude = longitude
		self.precipForecast = precipForecast
		self.precipForecast2 = precipForecast2
		self.precipForecastAmount = precipForecastAmount
		self.windSpeedVar = windSpeedVar
		self.dailyForecast = dailyForecast
		self.hourlyForecast = hourlyForecast
		self.weekForecast = weekForecast
		self.highTempVar = highTempVar
		self.locationName = locationName
		self.lowTempVar = lowTempVar
		self.symbolHourly = symbolHourly
		self.symbolVar = symbolVar
		self.tempHour = tempHour
		self.tempVar = tempVar
		self.windDirectionVar = windDirectionVar
		self.date = date
	}

	// Mark the function as async and potentially throwing to handle errors properly.
	func getWeather(for coordinate: CLLocationCoordinate2D) async throws {
		let weather = try await fetchWeather(for: coordinate)
		let current = weather.currentWeather
		let hourly = weather.hourlyForecast.first

		// Ensures daily and hourly forecasts are available; throws errors if not.
		guard let dailyForecast = await dailyForecast(for: coordinate), !dailyForecast.isEmpty else {
			throw CustomError.dailyForecastUnavailable
		}

		guard let firstHourlyForecast = hourly else {
			throw CustomError.hourlyForecastUnavailable
		}

		// Update properties based on the fetched weather data.
		precipForecast2 = firstHourlyForecast.precipitationChance
		precipForecast = firstHourlyForecast.precipitationAmount.value
		symbolHourly = firstHourlyForecast.symbolName
		tempHour = String(format: "%.0f", firstHourlyForecast.temperature.converted(to: .fahrenheit).value)
		tempVar = String(format: "%.0f", current.temperature.converted(to: .fahrenheit).value)
		highTempVar = String(format: "%.0f", dailyForecast.first?.highTemperature.converted(to: .fahrenheit).value ?? 0)
		lowTempVar = String(format: "%.0f", dailyForecast.first?.lowTemperature.converted(to: .fahrenheit).value ?? 0)
		windSpeedVar = current.wind.speed.converted(to: .milesPerHour).value
		windDirectionVar = CardinalDirection(course: current.wind.direction.converted(to: .degrees).value).rawValue
		symbolVar = current.symbolName
		locationName = distanceTracker.locationName

		// Process and store a 10-day weather forecast.
		let howManyDays = min(dailyForecast.count, 10)
		weekForecast = (0..<howManyDays).map { index in
			let dailyWeather = dailyForecast[index]
			let symbolName = dailyWeather.symbolName
			let minTemp = String(format: "%.0f", dailyWeather.lowTemperature.converted(to: .fahrenheit).value)
			let maxTemp = String(format: "%.0f", dailyWeather.highTemperature.converted(to: .fahrenheit).value)
			return Forecasts(symbolName: symbolName, minTemp: minTemp, maxTemp: maxTemp)
		}
	}


	/// ``getWeather(for:)``
	/// Initiates an asynchronous task to fetch current and forecasted weather data for a given coordinate.
	/// Utilizes `fetchWeather(for:)` to retrieve weather data which includes current weather and hourly forecasts.
	/// It processes this data to extract crucial information such as temperature, precipitation, and wind speed for both current and forecasted weather.
	/// Additionally, this method attempts to fetch a daily forecast, updating various properties with the received data for UI display.
	///
	/// Should any step of the data fetching process fail, this method handles errors appropriately,
	/// distinguishing between network-related errors (like no internet connection) and other types of errors by logging them or updating UI indicators.
	func getWeatherNonAsync(for coordinate: CLLocationCoordinate2D) {
		Task {
			do {
				let weather = try await fetchWeather(for: coordinate)
				let current = weather.currentWeather
				let hourly = weather.hourlyForecast.first

				// Checks for daily forecast availability and logs a message if unavailable.
				guard let dailyForecast = await dailyForecast(for: coordinate) else {
					print("Failed to fetch daily forecast. [getWeather]")
					return
				}

				// Ensures an hourly forecast is available, otherwise logs a message.
				guard let firstHourlyForecast = hourly else {
					print("firstHourlyForecast not available.  [getWeather]\n")
					return
				}

				// Updates properties based on the fetched weather data.
				precipForecast2 = firstHourlyForecast.precipitationChance
				precipForecast = firstHourlyForecast.precipitationAmount.value
				symbolHourly = firstHourlyForecast.symbolName
				tempHour = String(format: "%.0f", firstHourlyForecast.temperature.converted(to: .fahrenheit).value)
				tempVar = String(format: "%.0f", current.temperature.converted(to: .fahrenheit).value)
				highTempVar = String(format: "%.0f", dailyForecast.first?.highTemperature.converted(to: .fahrenheit).value ?? 0)
				lowTempVar = String(format: "%.0f", dailyForecast.first?.lowTemperature.converted(to: .fahrenheit).value ?? 0)
				windSpeedVar = current.wind.speed.converted(to: .milesPerHour).value
				windDirectionVar = CardinalDirection(course: current.wind.direction.converted(to: .degrees).value).rawValue
				symbolVar = current.symbolName
				locationName = distanceTracker.locationName

				// If the daily forecast data is empty, the method returns early.
				if dailyForecast.isEmpty {
					return
				}

				// Processes and stores a 10-day weather forecast.
				let howManyDays = min(dailyForecast.count, 10)
				weekForecast = (0..<howManyDays).map { index in
					let dailyWeather = dailyForecast[index]
					let symbolName = dailyWeather.symbolName
					let minTemp = String(format: "%.0f", dailyWeather.lowTemperature.converted(to: .fahrenheit).value)
					let maxTemp = String(format: "%.0f", dailyWeather.highTemperature.converted(to: .fahrenheit).value)
					return Forecasts(symbolName: symbolName, minTemp: minTemp, maxTemp: maxTemp)
				}
			} catch {
				// Handles specific URLError for no internet connection and other errors generically.
				if let error = error as? URLError, error.code == .notConnectedToInternet {
					print("Network error: The Internet connection appears to be offline.")
					isErrorAlert = true
				} else {
					print("\(error.localizedDescription) - [getWeather]")
				}
			}
		}
	}

	/// ``fetchWeather(for:)``
	/// Asynchronously fetches comprehensive weather data for a specified geographic coordinate.
	/// - Parameter coordinate: The `CLLocationCoordinate2D` representing the location to fetch weather data for.
	/// - Returns: A `Weather` object containing the current and forecasted weather conditions.
	/// - Throws: An error if the weather data could not be fetched.
	///
	/// Utilizes a detached task with `userInitiated` priority to fetch weather data using the shared weather service instance.
	/// This method converts the provided coordinate into a `CLLocation` object before making the fetch request.
	@discardableResult
	private func fetchWeather(for coordinate: CLLocationCoordinate2D) async throws -> Weather {
		let weather = try await Task.detached(priority: .userInitiated) { [self] in
			return try await self.sharedService.weather(for: self.convertToCLLocation(coordinate))
		}.value
		return weather
	}

	/// ``dailyForecast(for:)``
	/// Asynchronously fetches the daily weather forecast for a specific location.
	/// - Parameter coordinate: The `CLLocationCoordinate2D` of the location for which the daily forecast is requested.
	/// - Returns: An optional `Forecast<DayWeather>` containing the forecasted weather conditions for several days, or `nil` if the forecast could not be fetched.
	///
	/// Initiates a detached task to asynchronously fetch the daily forecast using the shared weather service.
	/// Prints the count of fetched daily weather data for debugging purposes.
	@discardableResult
	func dailyForecast(for coordinate: CLLocationCoordinate2D) async -> Forecast<DayWeather>? {
		let currentCoord = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
		let dayWeather = await Task.detached(priority: .userInitiated) {
			let dayForecast = try? await self.sharedService.weather(for: currentCoord, including: .daily)
			return dayForecast
		}.value
		print("dayWeather = \(dayWeather?.count ?? 0)")
		return dayWeather
	}

	/// ``hourlyForecast(for:)``
	/// Asynchronously fetches the hourly weather forecast for a specified location.
	/// - Parameter coordinate: The `CLLocationCoordinate2D` of the location for which the hourly forecast is requested.
	/// - Returns: An optional `Forecast<HourWeather>` containing the forecasted weather conditions for each hour, or `nil` if the forecast could not be fetched.
	///
	/// Similar to `dailyForecast(for:)`, this method uses a detached task to fetch hourly weather data, aiming to provide more granular weather information.
	@discardableResult
	func hourlyForecast(for coordinate: CLLocationCoordinate2D) async -> Forecast<HourWeather>? {
		let currentCoord = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
		let hourWeather = await Task.detached(priority: .userInitiated) {
			let hourForecast = try? await self.sharedService.weather(for: currentCoord, including: .hourly)
			return hourForecast
		}.value
		print("hourWeather = \(hourWeather?.count ?? 0)")
		return hourWeather
	}

	/// ``convertToCLLocation``
	/// Converts a `CLLocationCoordinate2D` object to a `CLLocation` object.
	/// - Parameter coordinate: The `CLLocationCoordinate2D` to convert.
	/// - Returns: A `CLLocation` object representing the same geographic location.
	///
	/// This utility method facilitates the conversion of coordinate objects into a format suitable for use with the weather fetching services.
	func convertToCLLocation(_ coordinate: CLLocationCoordinate2D) -> CLLocation {
		return CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
	}


	struct Forecasts: Identifiable {
		let id = UUID()
		let symbolName: String
		let minTemp: String
		let maxTemp: String
	}
}


