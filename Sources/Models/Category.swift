import Foundation

/// A news topic. Each category maps to one or more RSS feeds (see `Feeds`).
enum Category: String, CaseIterable, Codable, Identifiable {
    case world
    case science
    case technology
    case environment
    case sports
    case animals
    case space
    case politics
    case business
    case crime

    var id: String { rawValue }

    var title: String {
        switch self {
        case .world: return "World"
        case .science: return "Science"
        case .technology: return "Technology"
        case .environment: return "Environment"
        case .sports: return "Sports"
        case .animals: return "Animals"
        case .space: return "Space"
        case .politics: return "Politics"
        case .business: return "Business"
        case .crime: return "Crime"
        }
    }

    /// SF Symbol used in tabs and chips.
    var symbol: String {
        switch self {
        case .world: return "globe"
        case .science: return "atom"
        case .technology: return "cpu"
        case .environment: return "leaf"
        case .sports: return "sportscourt"
        case .animals: return "pawprint"
        case .space: return "moon.stars"
        case .politics: return "building.columns"
        case .business: return "chart.line.uptrend.xyaxis"
        case .crime: return "shield.lefthalf.filled"
        }
    }
}
