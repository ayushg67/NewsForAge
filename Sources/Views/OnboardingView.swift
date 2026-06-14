import SwiftUI

/// First-launch screen: enter age, preview the bracket, then continue.
struct OnboardingView: View {
    @Environment(AppSettings.self) private var settings
    @State private var ageText = ""
    @FocusState private var focused: Bool

    private var enteredAge: Int? {
        guard let value = Int(ageText), (1...120).contains(value) else { return nil }
        return value
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(.blue)
                Text("Newsphere")
                    .font(.largeTitle.bold())
                Text("Worldwide news, picked for your age.")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 8) {
                Text("How old are you?")
                    .font(.title3.weight(.semibold))
                TextField("Age", text: $ageText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .frame(maxWidth: 160)
                    .focused($focused)
            }

            if let age = enteredAge {
                BracketPreview(bracket: AgeBracket(age: age))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer()

            Button {
                settings.age = enteredAge
            } label: {
                Text("Show me the news")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(enteredAge == nil)
        }
        .padding(28)
        .animation(.easeInOut, value: enteredAge)
        .onAppear { focused = true }
    }
}

struct BracketPreview: View {
    let bracket: AgeBracket

    var body: some View {
        VStack(spacing: 10) {
            Text("You'll see the \(bracket.title) feed")
                .font(.subheadline.weight(.semibold))
            Text(bracket.blurb)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            FlowChips(categories: bracket.allowedCategories)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }
}

/// Simple wrapping row of category chips.
struct FlowChips: View {
    let categories: [Category]

    var body: some View {
        let columns = [GridItem(.adaptive(minimum: 84), spacing: 8)]
        LazyVGrid(columns: columns, alignment: .center, spacing: 8) {
            ForEach(categories) { category in
                Label(category.title, systemImage: category.symbol)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.blue.opacity(0.15), in: Capsule())
            }
        }
    }
}
