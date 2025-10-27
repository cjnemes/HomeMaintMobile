import SwiftUI

// MARK: - DetailRow

/// A reusable row component for displaying labeled details with an icon
struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.body)
                    .foregroundColor(valueColor)
            }
        }
    }
}

// MARK: - StatusBadge

/// A badge component for displaying task status with color coding
struct StatusBadge: View {
    let status: MaintenanceTask.TaskStatus

    var body: some View {
        Text(status.displayText)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(6)
    }

    private var backgroundColor: Color {
        switch status {
        case .pending: return .orange
        case .inProgress: return .blue
        case .completed: return .green
        case .cancelled: return .gray
        }
    }
}
