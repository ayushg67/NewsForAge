import SwiftUI

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    var retry: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title3.weight(.semibold))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let retry {
                Button("Try again", action: retry)
                    .buttonStyle(.bordered)
                    .padding(.top, 4)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Skeleton placeholder rows shown while the first fetch is in flight.
struct LoadingList: View {
    var body: some View {
        List(0..<6, id: \.self) { _ in
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 4).frame(height: 16)
                    RoundedRectangle(cornerRadius: 4).frame(height: 16).frame(maxWidth: 220)
                    RoundedRectangle(cornerRadius: 4).frame(height: 12).frame(maxWidth: 120)
                }
                RoundedRectangle(cornerRadius: 10).frame(width: 84, height: 84)
            }
            .foregroundStyle(.quaternary)
            .redacted(reason: .placeholder)
            .padding(.vertical, 4)
        }
        .listStyle(.plain)
    }
}
