import SwiftUI

/// One permission of one role.
///
/// The switch writes straight into the role, which is the only definition of what a
/// person can do. Sensitive permissions are marked so the consequence of handing one
/// over is visible before it is handed over.
struct PermissionToggleRow: View {
    let permission: Permission
    let isOn: Bool
    var isLocked: Bool = false
    let onChange: (Bool) -> Void

    var body: some View {
        Toggle(
            isOn: Binding(
                get: { isOn },
                set: { onChange($0) }
            )
        ) {
            VStack(alignment: .leading, spacing: 2) {
                Text(permission.title)
                    .font(.subheadline)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if permission.isSensitive {
                    Text("Jautri teisė")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Palette.terracotta)
                }
            }
        }
        .tint(Palette.forest)
        .disabled(isLocked)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(minHeight: 52)
    }
}
