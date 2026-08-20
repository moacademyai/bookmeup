import SwiftUI

/// Time away from the floor.
///
/// Approving is a real decision with real consequences, so the screen is honest about
/// what it cannot yet tell: which appointments a confirmed absence would touch. That
/// check belongs here and the data model already carries the dates it needs.
struct OwnerLeaveView: View {
    @Environment(BusinessStore.self) private var business

    private var pending: [LeaveRequest] { business.pendingLeaveRequests }

    private var decided: [LeaveRequest] {
        business.leaveRequests
            .filter { $0.status != .pending }
            .sorted { $0.start > $1.start }
    }

    private var canDecide: Bool { business.can(.manageLeave) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                OwnerSection(title: "Laukia sprendimo", accessory: pending.isEmpty ? nil : "\(pending.count)") {
                    if pending.isEmpty {
                        OwnerEmptyState(
                            title: "Prašymų nėra",
                            message: "Kai darbuotojas paprašys laisvos dienos, atostogų ar nedarbingumo, prašymas atsiras čia.",
                            symbolName: "checkmark.circle"
                        )
                    } else {
                        VStack(spacing: 10) {
                            ForEach(pending) { request in
                                card(request, showsActions: canDecide)
                            }
                        }
                    }
                }

                if !decided.isEmpty {
                    OwnerSection(title: "Istorija") {
                        VStack(spacing: 10) {
                            ForEach(decided) { request in
                                card(request, showsActions: false)
                            }
                        }
                    }
                }

                OwnerSection(title: "Prieš patvirtinant") {
                    OwnerEmptyState(
                        title: "Paveiktos rezervacijos",
                        message: "Kitas žingsnis — prieš patvirtinant nedarbą parodyti, kurie vizitai tuo metu suplanuoti ir ką su jais daryti.",
                        symbolName: "calendar.badge.exclamationmark"
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .background(Palette.bone)
        .scrollIndicators(.hidden)
        .navigationTitle(OwnerModule.leave.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Palette.bone, for: .navigationBar)
    }

    private func card(_ request: LeaveRequest, showsActions: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: request.kind.symbolName)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.forest)
                    .frame(width: 34, height: 34)
                    .background(Palette.eucalyptus.opacity(0.35), in: .circle)

                VStack(alignment: .leading, spacing: 3) {
                    Text(business.staffMember(with: request.staffID)?.memberName ?? "Darbuotojas")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.ink)
                    Text("\(request.kind.title) · \(request.rangeText)")
                        .font(.caption)
                        .foregroundStyle(Palette.inkSoft)
                }

                Spacer(minLength: 4)

                OwnerStatusBadge(
                    text: request.status.title,
                    tone: request.status == .approved ? .positive : (request.status == .rejected ? .critical : .warning)
                )
            }

            if !request.note.isEmpty {
                Text(request.note)
                    .font(.footnote)
                    .foregroundStyle(Palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if showsActions {
                HStack(spacing: 10) {
                    Button {
                        business.decideLeave(request, status: .approved)
                    } label: {
                        Text("Patvirtinti")
                    }
                    .buttonStyle(MarigoldButtonStyle())

                    Button {
                        business.decideLeave(request, status: .rejected)
                    } label: {
                        Text("Atmesti")
                    }
                    .buttonStyle(QuietButtonStyle(tint: Palette.terracotta))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(padding: 16)
    }
}
