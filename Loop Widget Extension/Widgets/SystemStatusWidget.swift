//
//  SystemStatusWidget.swift
//  Loop
//
//  Created by Noah Brauner on 8/15/22.
//  Copyright © 2022 LoopKit Authors. All rights reserved.
//

import LoopKit
import LoopUI
import SwiftUI
import WidgetKit

@available(iOS 16.1, *)
struct SystemStatusWidgetEntryView : View {
    
    @Environment(\.widgetFamily) private var widgetFamily
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode
    
    var entry: StatusWidgetTimelineProvider.Entry

    private var tileBackground: Color {
        widgetRenderingMode == .accented
            ? Color(UIColor.systemBackground).opacity(0.15)
            : Color("WidgetSecondaryBackground")
    }

    var body: some View {
        Group {
            if widgetFamily == .systemSmall {
                smallLayout
            } else {
                mediumLayout
            }
        }
        .foregroundColor(entry.contextIsStale ? Color(UIColor.systemGray3) : nil)
        .padding(5)
        .widgetBackground()
    }

    // Standard Loop small widget (unchanged)
    private var smallLayout: some View {
        VStack(alignment: .center, spacing: 5) {
            HStack(alignment: .center, spacing: 15) {
                LoopCircleView(entry: entry)

                GlucoseView(entry: entry)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(5)
            .background(tileBackground)
            .clipShape(ContainerRelativeShape())

            PumpView(entry: entry)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(5)
                .background(tileBackground)
                .clipShape(ContainerRelativeShape())
        }
    }

    // Sara's Pancreas medium widget: glucose + 3h chart on the left, IOB/COB and three buttons on the right
    private var mediumLayout: some View {
        HStack(alignment: .center, spacing: 6) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 8) {
                    LoopCircleView(entry: entry)

                    GlucoseView(entry: entry)

                    Spacer(minLength: 0)

                    if let fetchedAt = entry.glucoseFetchedAt, let glucoseDate = entry.currentGlucose?.startDate {
                        Text(ageString(from: glucoseDate, to: max(fetchedAt, entry.date)))
                            .font(.footnote)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                }
                .padding(.horizontal, 4)

                Group {
                    if let unit = entry.unit {
                        WidgetGlucoseChartView(
                            samples: entry.glucoseHistory,
                            unit: unit,
                            historyInterval: StatusWidgetTimelineProvider.chartHistoryInterval,
                            isStale: entry.glucoseIsStale
                        )
                    } else {
                        PumpView(entry: entry)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(4)
                .background(tileBackground)
                .clipShape(ContainerRelativeShape())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(alignment: .center, spacing: 5) {
                HStack(alignment: .center, spacing: 5) {
                    statTile(title: "IOB", value: iobString, color: Color("insulin"))
                    statTile(title: "COB", value: cobString, color: Color("fresh"))
                }

                HStack(alignment: .center, spacing: 5) {
                    SystemActionLink(to: .carbEntry)

                    SystemActionLink(to: .bolus)

                    SystemActionLink(to: .customPreset, active: entry.customPresetActive)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private func statTile(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text(title)
                .font(.footnote)
                .foregroundColor(Color(UIColor.secondaryLabel))
            Text(value)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(entry.contextIsStale ? Color(UIColor.systemGray3) : color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(5)
        .background(tileBackground)
        .clipShape(ContainerRelativeShape())
    }

    private static let iobFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 1
        f.maximumFractionDigits = 1
        return f
    }()

    private var iobString: String {
        guard let iob = entry.activeInsulin, let text = Self.iobFormatter.string(from: NSNumber(value: iob)) else {
            return "– U"
        }
        return "\(text) U"
    }

    private var cobString: String {
        guard let cob = entry.carbsOnBoard else {
            return "– g"
        }
        return "\(Int(cob.rounded())) g"
    }

    private func ageString(from: Date, to: Date) -> String {
        let minutes = max(0, Int(to.timeIntervalSince(from) / 60))
        return minutes < 60 ? "\(minutes) min" : "\(minutes / 60) h"
    }
}

@available(iOS 16.1, *)
struct SystemStatusWidget: Widget {
    let kind: String = "SystemStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StatusWidgetTimelineProvider()) { entry in
            SystemStatusWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Loop Status Widget")
        .description("See your current blood glucose and insulin delivery.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabledIfAvailable()
    }
}
