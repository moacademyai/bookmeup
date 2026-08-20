import SwiftUI
import UIKit

/// Which stage of a hold the timeline is being told about.
nonisolated enum TimelineHoldPhase {
    case began
    case changed
    case ended
    case cancelled
}

/// A transparent layer that reads taps and holds on the timeline without ever
/// competing with the scroll views around it.
///
/// SwiftUI's `DragGesture` claims a touch the moment a finger lands, which starves
/// the enclosing scroll view's pan gesture — that is what made empty timeline space
/// unscrollable. UIKit recognisers can be told to run alongside every other
/// recogniser and to keep passing their touches through, so panning stays the
/// timeline's base interaction and tap / hold are only read on top of it.
struct TimelineTouchSurface: UIViewRepresentable {
    /// Creation is only offered on the signed-in specialist's own column.
    var isEnabled: Bool
    var onTap: (CGPoint) -> Void
    var onHold: (TimelineHoldPhase, CGPoint) -> Void

    /// Long enough to read as a deliberate hold, short enough to feel instant.
    private static let holdDuration: TimeInterval = 0.25
    /// Travel that still counts as a steady finger rather than the start of a scroll.
    private static let allowedMovement: CGFloat = 12

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        let hold = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleHold(_:))
        )
        hold.minimumPressDuration = Self.holdDuration
        hold.allowableMovement = Self.allowedMovement

        for recognizer in [tap, hold] as [UIGestureRecognizer] {
            // Never swallow or postpone a touch: the scroll view must stay free to
            // start panning at any moment, and it cancels these on its own once it does.
            recognizer.cancelsTouchesInView = false
            recognizer.delaysTouchesBegan = false
            recognizer.delaysTouchesEnded = false
            recognizer.delegate = context.coordinator
            view.addGestureRecognizer(recognizer)
        }

        context.coordinator.tap = tap
        context.coordinator.hold = hold
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.surface = self
        context.coordinator.tap?.isEnabled = isEnabled
        context.coordinator.hold?.isEnabled = isEnabled
    }

    func makeCoordinator() -> Coordinator { Coordinator(surface: self) }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var surface: TimelineTouchSurface
        weak var tap: UITapGestureRecognizer?
        weak var hold: UILongPressGestureRecognizer?

        init(surface: TimelineTouchSurface) {
            self.surface = surface
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let view = recognizer.view, !isScrolling(around: view) else { return }
            surface.onTap(recognizer.location(in: view))
        }

        @objc func handleHold(_ recognizer: UILongPressGestureRecognizer) {
            guard let view = recognizer.view else { return }
            let point = recognizer.location(in: view)

            switch recognizer.state {
            case .began:
                // A finger landing on moving content is stopping the scroll, not holding.
                guard !isScrolling(around: view) else {
                    recognizer.isEnabled = false
                    recognizer.isEnabled = surface.isEnabled
                    return
                }
                surface.onHold(.began, point)
            case .changed:
                surface.onHold(.changed, point)
            case .ended:
                surface.onHold(.ended, point)
            case .cancelled, .failed:
                surface.onHold(.cancelled, point)
            default:
                break
            }
        }

        /// Lets the scroll views, buttons and context menus recognise at the same time.
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
        ) -> Bool {
            true
        }

        private func isScrolling(around view: UIView) -> Bool {
            var candidate: UIView? = view.superview
            while let current = candidate {
                if let scrollView = current as? UIScrollView,
                   scrollView.isDragging || scrollView.isDecelerating {
                    return true
                }
                candidate = current.superview
            }
            return false
        }
    }
}
