import Foundation
import Observation

/// Loads the three bundled JSON files at launch. Together they are about 1 MB and fully local; no network needed.
@Observable
final class DataStore {
    private(set) var cards: [Card] = []
    private(set) var types: [TypeInfo] = []
    private(set) var summary: Summary?
    private(set) var participants: [Participant] = []
    private(set) var loadError: String?

    init() {
        do {
            cards = try Self.load([Card].self, from: "cards")
            let typesFile = try Self.load(TypesFile.self, from: "types")
            types = typesFile.types
            summary = typesFile.summary
            participants = try Self.load([Participant].self, from: "participants")
        } catch {
            loadError = "Could not load data: \(error)"
        }
    }

    private static func load<T: Decodable>(_ type: T.Type, from name: String) throws -> T {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            throw NSError(domain: "DataStore", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "\(name).json not found. Make sure it is added to the app target."])
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }

    func type(withID id: String) -> TypeInfo? {
        types.first { $0.id == id }
    }

    /// Number of participants who have a type (452)
    var typedCount: Int { summary?.nWithRevealed ?? types.reduce(0) { $0 + $1.count } }

    /// Draws n random cards of the given gender; nil means both genders
    func drawCards(_ n: Int, gender: String?, excluding used: Set<UUID> = []) -> [Card] {
        let pool = cards.filter { (gender == nil || $0.partnerGender == gender) && !used.contains($0.id) }
        return Array(pool.shuffled().prefix(n))
    }
}
