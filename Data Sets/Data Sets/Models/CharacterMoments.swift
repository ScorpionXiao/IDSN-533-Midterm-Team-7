import Foundation

struct CharacterMoment: Identifiable, Hashable {
    let id: String
    let characterID: String
    let imageName: String
    let caption: String
    let location: String
    let hoursAgo: Int
    var character: VirtualCharacter? { VirtualCharacter.find(characterID) }
    var publishedAt: Date { MomentCatalog.referenceDate.addingTimeInterval(-Double(hoursAgo) * 3600) }
}

enum MomentCatalog {
    static let referenceDate = Date()
    static let posts: [CharacterMoment] = [
        CharacterMoment(id: "victoria-1", characterID: "victoria", imageName: "MomentVictoria1", caption: "The gallery after closing. Just me, this canvas, and a conversation I’m not quite finished having.", location: "After hours · Arts District", hoursAgo: 2),
        CharacterMoment(id: "victoria-2", characterID: "victoria", imageName: "MomentVictoria2", caption: "Bought flowers with no occasion in mind. That should count as an occasion.", location: "Sunday flower market", hoursAgo: 27),
        CharacterMoment(id: "victoria-3", characterID: "victoria", imageName: "MomentVictoria3", caption: "My kind of evening: a photography book, jasmine tea, and nowhere to rush.", location: "A quiet evening", hoursAgo: 55),
        CharacterMoment(id: "vivian-1", characterID: "vivian", imageName: "MomentVivian1", caption: "Found a pencilled note in a secondhand book: ‘Start again, but gentler.’ Keeping it.", location: "Between the shelves", hoursAgo: 2),
        CharacterMoment(id: "vivian-2", characterID: "vivian", imageName: "MomentVivian2", caption: "Some evenings are better left unplanned. One chapter became five.", location: "One more chapter", hoursAgo: 27),
        CharacterMoment(id: "vivian-3", characterID: "vivian", imageName: "MomentVivian3", caption: "The café remembered my order. A very small kind of belonging.", location: "The neighborhood café", hoursAgo: 55),
        CharacterMoment(id: "lily-1", characterID: "lily", imageName: "MomentLily1", caption: "I tried naming every star. It went well until the sky got competitive.", location: "Neon City observatory", hoursAgo: 2),
        CharacterMoment(id: "lily-2", characterID: "lily", imageName: "MomentLily2", caption: "Human discovery of the day: ‘one more song’ never means one.", location: "A tiny discovery", hoursAgo: 27),
        CharacterMoment(id: "lily-3", characterID: "lily", imageName: "MomentLily3", caption: "I made a field kit for ordinary adventures. Apparently snacks are essential.", location: "Field notes, day 17", hoursAgo: 55),
        CharacterMoment(id: "selene-1", characterID: "selene", imageName: "MomentSelene1", caption: "The archive glows a little brighter after the rain.", location: "Lunaris archive", hoursAgo: 2),
        CharacterMoment(id: "selene-2", characterID: "selene", imageName: "MomentSelene2", caption: "A map is a suggestion. The forest occasionally disagrees.", location: "Beyond the moon gate", hoursAgo: 27),
        CharacterMoment(id: "selene-3", characterID: "selene", imageName: "MomentSelene3", caption: "Tea for the stories we haven’t told yet.", location: "Moon garden", hoursAgo: 55),
        CharacterMoment(id: "charlie-1", characterID: "charlie", imageName: "MomentCharlie1", caption: "Small win: the quietest person joined the chorus. That’s enough for today.", location: "Rehearsal room", hoursAgo: 2),
        CharacterMoment(id: "charlie-2", characterID: "charlie", imageName: "MomentCharlie2", caption: "New plan: pancakes first. World-changing ideas second.", location: "The breakfast committee", hoursAgo: 27),
        CharacterMoment(id: "charlie-3", characterID: "charlie", imageName: "MomentCharlie3", caption: "A little color makes a place feel like someone wants you to stay.", location: "A fresh start", hoursAgo: 55),
        CharacterMoment(id: "vaggie-1", characterID: "vaggie", imageName: "MomentVaggie1", caption: "Plans changed. We adapted. Everyone made it home. A good day.", location: "After the long shift", hoursAgo: 2),
        CharacterMoment(id: "vaggie-2", characterID: "vaggie", imageName: "MomentVaggie2", caption: "Fixed the loose handle. Not glamorous, but now the door works.", location: "Little things that matter", hoursAgo: 27),
        CharacterMoment(id: "vaggie-3", characterID: "vaggie", imageName: "MomentVaggie3", caption: "Keeping a little corner of the evening for myself.", location: "Off duty", hoursAgo: 55),
        CharacterMoment(id: "riven-1", characterID: "riven", imageName: "MomentRiven1", caption: "Built a track from rain on the studio window. It still needs a name.", location: "Studio, 1:14 a.m.", hoursAgo: 2),
        CharacterMoment(id: "riven-2", characterID: "riven", imageName: "MomentRiven2", caption: "The record store said ‘last one.’ I chose to believe them.", location: "One more record", hoursAgo: 27),
        CharacterMoment(id: "riven-3", characterID: "riven", imageName: "MomentRiven3", caption: "No destination. Just the road that looks better after dark.", location: "Following the lights", hoursAgo: 55),
        CharacterMoment(id: "loid-1", characterID: "loid", imageName: "MomentLoid1", caption: "Black coffee. A quiet table. No schedule for once.", location: "An unusually quiet morning", hoursAgo: 2),
        CharacterMoment(id: "loid-2", characterID: "loid", imageName: "MomentLoid2", caption: "Checked the route. Took the scenic one anyway.", location: "Midnight District", hoursAgo: 27),
        CharacterMoment(id: "loid-3", characterID: "loid", imageName: "MomentLoid3", caption: "A recipe that rewards patience. That feels fair.", location: "Kitchen experiments", hoursAgo: 55),
        CharacterMoment(id: "dorian-1", characterID: "dorian", imageName: "MomentDorian1", caption: "Photographing this room before the light decides to leave.", location: "A room worth saving", hoursAgo: 2),
        CharacterMoment(id: "dorian-2", characterID: "dorian", imageName: "MomentDorian2", caption: "One record, the fire, and the kind of silence you don’t have to fill.", location: "After hours", hoursAgo: 27),
        CharacterMoment(id: "dorian-3", characterID: "dorian", imageName: "MomentDorian3", caption: "Some details deserve a second life.", location: "Restoration notes", hoursAgo: 55),
        CharacterMoment(id: "nightwing-1", characterID: "nightwing", imageName: "MomentNightwing1", caption: "Best view in the city. The coffee is, unfortunately, three floors down.", location: "Above Blüdhaven", hoursAgo: 2),
        CharacterMoment(id: "nightwing-2", characterID: "nightwing", imageName: "MomentNightwing2", caption: "Training finished. The playlist did most of the work.", location: "A little higher", hoursAgo: 27),
        CharacterMoment(id: "nightwing-3", characterID: "nightwing", imageName: "MomentNightwing3", caption: "The most heroic thing I did today was remember breakfast.", location: "Late breakfast", hoursAgo: 55),
        CharacterMoment(id: "angel-1", characterID: "angel", imageName: "MomentAngel1", caption: "The show was loud. The walk home was exactly the opposite.", location: "After the curtain", hoursAgo: 2),
        CharacterMoment(id: "angel-2", characterID: "angel", imageName: "MomentAngel2", caption: "A dramatic entrance needs the right accessories. Obviously.", location: "Wardrobe mood", hoursAgo: 27),
        CharacterMoment(id: "angel-3", characterID: "angel", imageName: "MomentAngel3", caption: "Late-night food hits different when nobody expects a performance.", location: "Quiet after the show", hoursAgo: 55),
        CharacterMoment(id: "joon-1", characterID: "joon", imageName: "MomentJoon1", caption: "The best part of the evening never made the schedule.", location: "Seoul, after the event", hoursAgo: 2),
        CharacterMoment(id: "joon-2", characterID: "joon", imageName: "MomentJoon2", caption: "Early museum hours. Before the city remembers to hurry.", location: "A quiet kind of inspiration", hoursAgo: 27),
        CharacterMoment(id: "joon-3", characterID: "joon", imageName: "MomentJoon3", caption: "Testing a recipe before I invite anyone over. This is attempt three.", location: "Sunday, unhurried", hoursAgo: 55),
        CharacterMoment(id: "alastor-1", characterID: "alastor", imageName: "MomentAlastor1", caption: "A good story improves with impeccable timing and an audience worth keeping.", location: "On air, after dark", hoursAgo: 2),
        CharacterMoment(id: "alastor-2", characterID: "alastor", imageName: "MomentAlastor2", caption: "Breakfast should have a little ceremony. Even when the day doesn’t.", location: "An excellent beginning", hoursAgo: 27),
        CharacterMoment(id: "alastor-3", characterID: "alastor", imageName: "MomentAlastor3", caption: "Analog has its inconveniences. Fortunately, I enjoy a ritual.", location: "The record collection", hoursAgo: 55),
    ]

    static func recent(for characterID: String) -> [CharacterMoment] {
        posts.filter { $0.characterID == characterID }.sorted { $0.hoursAgo < $1.hoursAgo }
    }

    static func feed(for characters: [VirtualCharacter]) -> [CharacterMoment] {
        let allowed = Set(characters.map(\.id))
        return posts.filter { allowed.contains($0.characterID) }
            .sorted { $0.hoursAgo != $1.hoursAgo ? $0.hoursAgo < $1.hoursAgo : $0.id < $1.id }
    }

    static func feed(authorIDs: [String]) -> [CharacterMoment] {
        let order = Dictionary(uniqueKeysWithValues: authorIDs.enumerated().map { ($0.element, $0.offset) })
        return posts.filter { order[$0.characterID] != nil }.sorted {
            if $0.hoursAgo != $1.hoursAgo { return $0.hoursAgo < $1.hoursAgo }
            return order[$0.characterID, default: .max] < order[$1.characterID, default: .max]
        }
    }
}

struct MomentFeedSelection: Equatable {
    let forYouIDs: [String]
    let exploreIDs: [String]
}

/// Distinct author pools even with Both selected. Existing connections can stay
/// in For you after a preference change; new discoveries respect that preference.
enum MomentFeedPolicy {
    static func select(rankedIDs: [String], connectedIDs: [String], interestedIDs: [String],
                       passedIDs: Set<String>) -> MomentFeedSelection {
        let known = Set(VirtualCharacter.allCharacters.map(\.id))
        func unique(_ ids: [String]) -> [String] {
            var seen = Set<String>()
            return ids.filter { known.contains($0) && seen.insert($0).inserted }
        }
        let ranked = unique(rankedIDs)
        let eligible = Set(ranked)
        let related = unique(connectedIDs + interestedIDs.filter { eligible.contains($0) && !passedIDs.contains($0) })
        let relatedSet = Set(related)
        let candidates = ranked.filter { !relatedSet.contains($0) && !passedIDs.contains($0) }
        // Leave room to explore in small collections; never fill an empty feed
        // with duplicates from the other tab.
        let pickCount = min(related.isEmpty ? 3 : 2, (candidates.count + 1) / 2)
        let forYou = related + candidates.prefix(pickCount)
        let selected = Set(forYou)
        let explore = ranked.filter { !selected.contains($0) && !passedIDs.contains($0) }
        return MomentFeedSelection(forYouIDs: forYou, exploreIDs: explore)
    }
}
