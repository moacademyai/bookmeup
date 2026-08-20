import SwiftUI

/// Example requests, appearing and fading inside the assistant box.
///
/// This is the assistant teaching itself. Several examples live on screen at once, each
/// on its own rhythm: one is being typed while another is already resting and a third is
/// quietly leaving. Nothing blinks, nothing races — the movement is slow enough to read
/// and slow enough to ignore.
///
/// Tapping one drops it into the field, which is the shortest path from "what is this"
/// to "I asked for something".
struct AssistantPromptCloud: View {
    let prompts: [String]
    /// How many examples share the box. Four fills the space without becoming a list.
    var lineCount: Int = 4
    var onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(0..<min(lineCount, max(prompts.count, 1)), id: \.self) { index in
                AssistantPromptLine(
                    prompts: prompts,
                    startIndex: index,
                    stride: lineCount,
                    order: index,
                    onSelect: onSelect
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pavyzdiniai klausimai")
    }
}

/// One line of the cloud, running its own independent cycle.
///
/// Each line walks its own slice of the list — line 0 takes every fourth example starting
/// at the first, line 1 starting at the second — so two lines can never show the same
/// example at the same time without any shared state between them.
private struct AssistantPromptLine: View {
    let prompts: [String]
    let startIndex: Int
    let stride: Int
    /// Position in the box, used only to stagger the entrance.
    let order: Int
    var onSelect: (String) -> Void

    @State private var typed = ""
    @State private var current = ""
    @State private var isVisible = false

    var body: some View {
        Button {
            guard !current.isEmpty else { return }
            onSelect(current)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.turn.down.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Palette.forest.opacity(0.5))
                Text(typed)
                    .font(.subheadline)
                    .foregroundStyle(Palette.inkSoft)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 26, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(ExperienceCardPressStyle())
        .opacity(isVisible ? 1 : 0)
        .blur(radius: isVisible ? 0 : 2)
        .disabled(typed.isEmpty)
        .animation(.easeInOut(duration: 0.55), value: isVisible)
        .task(id: prompts) { await cycle() }
        .accessibilityLabel(current.isEmpty ? "Pavyzdys" : current)
        .accessibilityHint("Įrašyti šį klausimą")
    }

    /// Runs while the view is on screen. Every sleep is a cancellation point, so leaving
    /// the screen stops the animation immediately.
    private func cycle() async {
        guard !prompts.isEmpty else { return }

        // Staggered entrance: the lines are never in step with one another.
        try? await Task.sleep(for: .milliseconds(order * 850))
        if Task.isCancelled { return }

        var step = 0
        while !Task.isCancelled {
            let index = (startIndex + step * stride) % prompts.count
            let prompt = prompts[index]
            current = prompt
            typed = ""
            isVisible = true

            for offset in 1...prompt.count {
                typed = String(prompt.prefix(offset))
                try? await Task.sleep(for: .milliseconds(28))
                if Task.isCancelled { return }
            }

            // Each line rests a little longer than the one above it, so they drift apart
            // instead of pulsing together.
            try? await Task.sleep(for: .milliseconds(3200 + order * 400))
            if Task.isCancelled { return }

            isVisible = false
            try? await Task.sleep(for: .milliseconds(700))
            if Task.isCancelled { return }

            step += 1
        }
    }
}
