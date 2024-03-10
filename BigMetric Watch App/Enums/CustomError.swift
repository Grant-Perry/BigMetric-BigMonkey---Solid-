//   CustomError.swift
//   BigMetric Watch App
//
//   Created by: Grant Perry on 3/9/24 at 9:34 AM
//     Modified: 
//
//  Copyright © 2024 Delicious Studios, LLC. - Grant Perry
//

import Foundation
import SwiftUI

enum CustomError: Error {
	case geocodingError(String)
	case cityNotFound
	case unknownError
	case dailyForecastUnavailable
	case hourlyForecastUnavailable
}

// Example of how to use it:
// continuation.resume(throwing: CustomError.geocodingError("Reverse geocoding failed with error: \(error.localizedDescription)"))
// continuation.resume(throwing: CustomError.cityNotFound)

