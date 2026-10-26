//
//  LoopCoreConstants.swift
//  LoopCore
//
//  Created by Pete Schwamb on 10/16/20.
//  Copyright © 2020 LoopKit Authors. All rights reserved.
//

import Foundation
import LoopKit

public enum LoopCoreConstants {
    /// The amount of time since a given date that input data should be considered valid
    public static let inputDataRecencyInterval = TimeInterval(minutes: 15)
    
    /// The amount of time in the future a glucose value should be considered valid
    public static let futureGlucoseDataInterval = TimeInterval(minutes: 5)

    // Sara's Pancreas: GLP-1 slows absorption, so presets are 3h / 4.5h / 6h with 4.5h (medium) pre-selected
    public static let defaultCarbAbsorptionTimes: CarbStore.DefaultAbsorptionTimes = (fast: .hours(3), medium: .hours(4.5), slow: .hours(6))

    /// How much historical glucose to include in a dosing decision
    /// Somewhat arbitrary, but typical maximum visible in bolus glucose preview
    public static let dosingDecisionHistoricalGlucoseInterval = TimeInterval(hours: 2)
}
