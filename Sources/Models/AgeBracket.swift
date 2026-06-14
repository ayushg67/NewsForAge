import Foundation

/// The three age groups that gate which news categories a reader can see.
enum AgeBracket: String, CaseIterable, Codable, Identifiable {
    case kids
    case teens
    case adults

    var id: String { rawValue }

    init(age: Int) {
        switch age {
        case ..<13: self = .kids
        case 13...17: self = .teens
        default: self = .adults
        }
    }

    var title: String {
        switch self {
        case .kids: return "Kids"
        case .teens: return "Teens"
        case .adults: return "Adults"
        }
    }

    var ageRangeDescription: String {
        switch self {
        case .kids: return "Under 13"
        case .teens: return "13–17"
        case .adults: return "18 and up"
        }
    }

    var blurb: String {
        switch self {
        case .kids:
            return "Friendly stories about science, sports, animals and space."
        case .teens:
            return "World events, technology and the environment, plus the kids' topics."
        case .adults:
            return "Full worldwide coverage including politics, business and crime."
        }
    }

    /// Categories visible to this bracket, in display order. Younger brackets
    /// are subsets of older ones — access only widens with age.
    var allowedCategories: [Category] {
        switch self {
        case .kids:
            return [.science, .sports, .animals, .space]
        case .teens:
            return [.world, .science, .technology, .environment, .sports, .animals, .space]
        case .adults:
            return Category.allCases
        }
    }
}
