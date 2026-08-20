import SwiftUI

/// One specialist's vertical day column: appointments and personal blocks placed
/// at their real time, empty time left empty.
///
/// Scrolling is the base interaction of the whole surface: no gesture here ever
/// claims a touch, so a swipe started anywhere pans the timeline. Tap and hold are
/// read on top of that by `TimelineTouchSurface`, and both drop out the moment the
/// scroll views take over.
struct CalendarTimelineColumn: View {
    let day: Date
    let items: [CalendarItem]
    var showsNowLine: Bool
    var isNarrow: Bool = false
    /// Tints the signed-in specialist's own column just enough to find it instantly
    /// in a wide team view. Every column is bookable either way.
    var isCurrentUser: Bool = true
    var onOpenBooking: (Booking) -> Void
    var onCreate: (Date) -> Void
    var onRemoveBlock: (TimeBlock) -> Void
    /// Tells the host when a hold selection owns the touch, so the surrounding
    /// scroll views stand down until the finger lifts.
    var onSelectionActive: (Bool) -> Void = { _ in }

    @State private var pressedTime: Date?

    private var positioned: [PositionedCalendarItem] { CalendarLayout.position(items) }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                grid

                TimelineTouchSurface(
                    isEnabled: true,
                    onTap: { point in handleTap(at: point, columnWidth: proxy.size.width) },
                    onHold: { phase, point in
                        handleHold(phase, at: point, columnWidth: proxy.size.width)
                    }
                )
                .frame(width: proxy.size.width, height: CalendarLayout.totalHeight)

                if let pressedTime {
                    highlight(at: pressedTime)
                }

                ForEach(positioned) { placed in
                    let size = CGSize(
                        width: width(for: placed, in: proxy.size.width),
                        height: CalendarLayout.height(forMinutes: placed.item.minutes)
                    )
                    itemView(placed, height: size.height)
                        .frame(width: size.width, height: size.height)
                        .offset(
                            x: xOffset(for: placed, in: proxy.size.width),
                            y: CalendarLayout.offset(for: placed.item.start, on: day)
                        )
                }

                if showsNowLine, let offset = nowOffset {
                    nowLine.offset(y: offset)
                }
            }
        }
        .frame(height: CalendarLayout.totalHeight)
        .sensoryFeedback(trigger: pressedTime) { previous, current in
            guard current != nil else { return nil }
            return previous == nil ? .impact(weight: .medium) : .selection
        }
        .onChange(of: day) { _, _ in cancelSelection() }
        .onDisappear { cancelSelection() }
    }

    // MARK: - Layers

    private var grid: some View {
        ZStack(alignment: .topLeading) {
            isCurrentUser ? CalendarTheme.canvas : CalendarTheme.ownColumnTint
            ForEach(CalendarLayout.halfHourMarks, id: \.self) { minutes in
                Rectangle()
                    .fill(minutes % 60 == 0 ? CalendarTheme.hairline : CalendarTheme.softLine)
                    .frame(height: 0.5)
                    .offset(y: CGFloat(minutes) * CalendarLayout.minuteHeight)
            }
        }
    }

    private func highlight(at time: Date) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(CalendarTheme.accent.opacity(0.16))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(CalendarTheme.accent, lineWidth: 1.5)
            }
            .overlay(alignment: .leading) {
                Text(time.timeText)
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(CalendarTheme.accent)
                    .padding(.leading, 6)
            }
            .frame(height: CalendarLayout.height(forMinutes: 30))
            .offset(y: CalendarLayout.offset(for: time, on: day))
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private func itemView(_ placed: PositionedCalendarItem, height: CGFloat) -> some View {
        switch placed.item {
        case .booking(let booking):
            Button {
                onOpenBooking(booking)
            } label: {
                CalendarAppointmentBlock(booking: booking, height: height, isNarrow: isNarrow)
            }
            .buttonStyle(.plain)

        case .block(let block):
            CalendarBlockBlock(block: block, height: height, isNarrow: isNarrow)
                .contextMenu {
                    Button("Pašalinti bloką", systemImage: "trash", role: .destructive) {
                        onRemoveBlock(block)
                    }
                }
        }
    }

    private var nowLine: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(CalendarTheme.now)
                .frame(height: 1.5)
            Circle()
                .fill(CalendarTheme.now)
                .frame(width: 6, height: 6)
                .offset(x: -2)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Geometry

    private var nowOffset: CGFloat? {
        guard AppDate.isSameDay(day, Date()) else { return nil }
        let minutes = CalendarLayout.minutesFromStart(of: Date(), on: day)
        guard minutes >= 0, minutes <= CalendarLayout.totalMinutes else { return nil }
        return CGFloat(minutes) * CalendarLayout.minuteHeight
    }

    private func width(for placed: PositionedCalendarItem, in total: CGFloat) -> CGFloat {
        let usable = max(total - 3, 40)
        return usable / CGFloat(placed.laneCount)
    }

    private func xOffset(for placed: PositionedCalendarItem, in total: CGFloat) -> CGFloat {
        width(for: placed, in: total) * CGFloat(placed.lane) + 2
    }

    // MARK: - Touch handling

    /// A tap lands straight on the time it touched. Cards handle their own taps,
    /// so anything landing on one is left alone.
    private func handleTap(at point: CGPoint, columnWidth: CGFloat) {
        guard isFreeSpace(point, columnWidth: columnWidth) else { return }
        onCreate(CalendarLayout.time(atOffset: point.y, on: day))
    }

    /// A hold opens a selection that follows the finger until it lifts.
    private func handleHold(_ phase: TimelineHoldPhase, at point: CGPoint, columnWidth: CGFloat) {
        switch phase {
        case .began:
            guard isFreeSpace(point, columnWidth: columnWidth) else { return }
            pressedTime = CalendarLayout.time(atOffset: point.y, on: day)
            onSelectionActive(true)

        case .changed:
            guard pressedTime != nil else { return }
            let time = CalendarLayout.time(atOffset: point.y, on: day)
            if pressedTime != time { pressedTime = time }

        case .ended:
            guard let time = pressedTime else { return }
            cancelSelection()
            onCreate(time)

        case .cancelled:
            cancelSelection()
        }
    }

    private func cancelSelection() {
        guard pressedTime != nil else { return }
        pressedTime = nil
        onSelectionActive(false)
    }

    /// True when the point is on open time rather than on an appointment or block.
    private func isFreeSpace(_ point: CGPoint, columnWidth: CGFloat) -> Bool {
        !positioned.contains { placed in
            let top = CalendarLayout.offset(for: placed.item.start, on: day)
            let bottom = top + CalendarLayout.height(forMinutes: placed.item.minutes)
            guard point.y >= top, point.y <= bottom else { return false }
            let left = xOffset(for: placed, in: columnWidth)
            return point.x >= left && point.x <= left + width(for: placed, in: columnWidth)
        }
    }
}

/// How much text a timeline card can show without clipping.
nonisolated enum CalendarCardDensity {
    /// Roughly one line of caption text plus the card's vertical padding.
    static func lineCount(forHeight height: CGFloat) -> Int {
        let usable = height - 9
        return max(Int(usable / 13), 1)
    }
}

/// The appointment card drawn inside the timeline.
/// Priority when space runs out: client, then time, then service, then status.
struct CalendarAppointmentBlock: View {
    let booking: Booking
    let height: CGFloat
    var isNarrow: Bool = false

    private var lines: Int { CalendarCardDensity.lineCount(forHeight: height) }

    private var timeText: String {
        isNarrow
            ? booking.start.timeText
            : "\(booking.start.timeText)–\(booking.end.timeText)"
    }

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(booking.status.tint)
                .frame(width: 3)
            VStack(alignment: .leading, spacing: 1) {
                Text(booking.clientName)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(CalendarTheme.label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                if lines >= 2 {
                    Text(timeText)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(CalendarTheme.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                if lines >= 3 {
                    Text(booking.serviceName)
                        .font(.caption2)
                        .foregroundStyle(CalendarTheme.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                }

                if lines >= 4 {
                    statusMark
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background(booking.status.tint.opacity(0.12))
        .clipShape(.rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(booking.status.tint.opacity(0.35), lineWidth: 0.5)
        }
        .accessibilityLabel("\(booking.start.timeText), \(booking.clientName), \(booking.serviceName), \(booking.status.title)")
    }

    private var statusMark: some View {
        HStack(spacing: 3) {
            Image(systemName: booking.status.symbolName)
                .font(.system(size: 9, weight: .semibold))
            Text(booking.status.title)
                .font(.system(size: 10, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .foregroundStyle(booking.status.tint)
    }
}

/// Personal time drawn inside the timeline.
struct CalendarBlockBlock: View {
    let block: TimeBlock
    let height: CGFloat
    var isNarrow: Bool = false

    private var lines: Int { CalendarCardDensity.lineCount(forHeight: height) }

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(CalendarTheme.tertiary)
                .frame(width: 3)
            VStack(alignment: .leading, spacing: 1) {
                Text(block.title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(CalendarTheme.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                if lines >= 2 {
                    Text(block.start.timeText)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(CalendarTheme.tertiary)
                        .lineLimit(1)
                }

                if lines >= 3 {
                    Text(isNarrow ? "\(block.durationMinutes) min." : "\(block.durationMinutes) min. · asmeninis laikas")
                        .font(.caption2)
                        .foregroundStyle(CalendarTheme.tertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background(CalendarTheme.fill)
        .clipShape(.rect(cornerRadius: 7))
        .accessibilityLabel("\(block.start.timeText), \(block.title), \(block.durationMinutes) minučių")
    }
}

/// Shared hour rail on the left of every timeline. Always visible.
struct CalendarTimeRail: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.clear
            ForEach(CalendarLayout.halfHourMarks, id: \.self) { minutes in
                Text(CalendarLayout.label(forMinutesFromStart: minutes))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(minutes % 60 == 0 ? CalendarTheme.secondary : CalendarTheme.tertiary)
                    .padding(.trailing, 6)
                    .offset(y: CGFloat(minutes) * CalendarLayout.minuteHeight - 6)
            }
        }
        .frame(width: CalendarLayout.railWidth, height: CalendarLayout.totalHeight, alignment: .topTrailing)
    }
}
