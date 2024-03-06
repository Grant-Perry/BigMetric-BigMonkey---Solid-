//
//  InsideButtonTextView.swift
//  howFar Watch App
//
//  Created by Grant Perry on 4/15/23.
//

import SwiftUI

struct InsideButtonTextView: View {
var distanceTracker: DistanceTracker
//var workoutManager: WorkoutManager

   var body: some View {
      VStack(spacing: 0) {
         VStack {
				let distanceIn = distanceTracker.distance
				if distanceIn > 0 {
//            if let distance = distanceTracker.distance, distance > 0 {
               Group {
						let distanceInYards = distanceTracker.yardsOrMiles ? distanceIn : distanceIn * distanceTracker.metersToYards 
                  let formattedDistance = String(format: distanceInYards > 100 ? "%.0f" : "%.2f", distanceInYards)

                  Text(formattedDistance)
                     .lineLimit(1)
                     .minimumScaleFactor(0.65)
                     .foregroundColor(distanceTracker.yardsOrMiles ? .white : .white)
                     .bold()

                  Text(distanceTracker.yardsOrMiles ? "Miles" : "Yards")
                     .font(.caption)
                     .frame(alignment: .trailing)
               }
               .font(.largeTitle)
               .fontWeight(.regular)
            } else {
//               if let distance = distanceTracker.distance {
						let formattedDistance = distanceTracker.showStartText ? "0.00" : String(format: "%.2f", distanceTracker.yardsOrMiles ? distanceIn : distanceIn * distanceTracker.metersToYards)

                  Text(formattedDistance)
                     .font(.title)
                     .multilineTextAlignment(.center)

                  Text(distanceTracker.yardsOrMiles ? "Miles" : "Yards")
                     .font(.caption)
                     .kerning(1.1)
                     .bold()
//               }
            }
         }
      }
   }
}

