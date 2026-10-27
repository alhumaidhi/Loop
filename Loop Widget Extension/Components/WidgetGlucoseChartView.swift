//
//  WidgetGlucoseChartView.swift
//  Loop Widget Extension
//
//  Sara's Pancreas customization: a small CGM-style glucose chart for the home-screen widget.
//  History only (last 3 hours), black dots, fixed 40–300 mg/dL scale, 70 and 200 reference lines.
//

import Charts
import HealthKit
import LoopKit
import SwiftUI

@available(iOS 16.0, *)
struct WidgetGlucoseChartView: View {
    let samples: [GlucoseValue]
    let unit: HKUnit
    let historyInterval: TimeInterval
    let isStale: Bool

    private struct Point: Identifiable {
        let id: Int
        let date: Date
        let value: Double
    }

    private var points: [Point] {
        let start = Date(timeIntervalSinceNow: -historyInterval)
        return samples.enumerated().compactMap { index, sample in
            guard sample.startDate >= start else { return nil }
            return Point(id: index, date: sample.startDate, value: sample.quantity.doubleValue(for: unit))
        }
    }

    private func value(_ mgdl: Double) -> Double {
        HKQuantity(unit: .milligramsPerDeciliter, doubleValue: mgdl).doubleValue(for: unit)
    }

    private var lowLine: Double { value(70) }
    private var highLine: Double { value(200) }
    private var yMin: Double { value(40) }
    private var yMax: Double {
        let top = value(300)
        let maxValue = points.map { $0.value }.max() ?? top
        return maxValue > top ? value(400) : top
    }

    private func label(for v: Double) -> String {
        unit == .milligramsPerDeciliter ? String(Int(v.rounded())) : String(format: "%.1f", v)
    }

    private var dotColor: Color {
        isStale ? Color(UIColor.systemGray3) : Color(UIColor.label)
    }

    var body: some View {
        let now = Date()
        let start = now.addingTimeInterval(-historyInterval)

        Chart {
            RuleMark(y: .value("High", highLine))
                .foregroundStyle(Color(red: 0.85, green: 0.64, blue: 0))
                .lineStyle(StrokeStyle(lineWidth: 1))
            RuleMark(y: .value("Low", lowLine))
                .foregroundStyle(Color(red: 0.85, green: 0.23, blue: 0.18))
                .lineStyle(StrokeStyle(lineWidth: 1))
            ForEach(points) { point in
                PointMark(
                    x: .value("Time", point.date),
                    y: .value("Glucose", point.value)
                )
                .symbolSize(14)
                .foregroundStyle(dotColor)
            }
        }
        .chartXScale(domain: start...now)
        .chartYScale(domain: yMin...yMax)
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .trailing, values: [lowLine, highLine]) { value in
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(label(for: v))
                            .font(.system(size: 9))
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                }
            }
        }
        .chartPlotStyle { plot in
            plot.padding(.leading, 4)
        }
        .overlay(alignment: .bottomLeading) {
            Text("3 HR")
                .font(.system(size: 9))
                .foregroundColor(Color(UIColor.secondaryLabel))
                .padding(.leading, 6)
                .padding(.bottom, 2)
        }
    }
}
