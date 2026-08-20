import SwiftUI

/// What kind of work is booked ahead.
///
/// This lives behind a tap rather than on the Today screen: knowing the split between
/// haircuts and beards is useful once a week, not every time the app opens.
struct UpcomingServicesSheet: View {
    let total: Int
    let services: [ServiceCount]
    let revenue: Double

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(total)")
                            .font(.system(size: 40, weight: .semibold).monospacedDigit())
                            .foregroundStyle(Palette.ink)
                        Text("Būsimi vizitai · \(revenue.asEuro)")
                            .font(.subheadline)
                            .foregroundStyle(Palette.inkSoft)
                    }

                    if services.isEmpty {
                        Text("Būsimų vizitų dar nėra.")
                            .font(.subheadline)
                            .foregroundStyle(Palette.inkSoft)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(services.enumerated()), id: \.element.id) { index, service in
                                row(service)
                                if index < services.count - 1 {
                                    Divider().overlay(Palette.hairline)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .background(Palette.bone)
            .scrollIndicators(.hidden)
            .navigationTitle("Artimiausi vizitai")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Uždaryti") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationContentInteraction(.scrolls)
    }

    private func row(_ service: ServiceCount) -> some View {
        HStack(spacing: 12) {
            Text(service.name)
                .font(.subheadline)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Text("\(service.count)")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(Palette.ink)
        }
        .padding(.vertical, 13)
    }
}
