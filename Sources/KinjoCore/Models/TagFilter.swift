// Copyright (C) 2025 KinjoCore Contributors
//
// Licensed under the EUPL, Version 1.2 or – as soon they will be approved by
// the European Commission - subsequent versions of the EUPL (the "Licence");
// You may not use this work except in compliance with the Licence.
// You may obtain a copy of the Licence at:
//
// https://joinup.ec.europa.eu/software/page/eupl
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the Licence is distributed on an "AS IS" basis,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the Licence for the specific language governing permissions and
// limitations under the Licence.

import Foundation

/// Filter options for filtering reminders by tags.
///
/// Tags are extracted from the reminder's notes field (e.g., #work, #important).
/// All tag comparisons are case-insensitive.
public enum TagFilter: Sendable, Hashable, Codable {

    /// No tag filtering applied.
    case none

    /// Filter reminders that have a specific tag.
    ///
    /// - Parameter tag: The tag to match (without # prefix, case-insensitive).
    case hasTag(String)

    /// Filter reminders that do NOT have a specific tag.
    ///
    /// - Parameter tag: The tag to exclude (without # prefix, case-insensitive).
    case notHasTag(String)

    /// Filter reminders that have at least one of the specified tags (OR logic).
    ///
    /// - Parameter tags: The tags to match (without # prefix, case-insensitive).
    case hasAnyTag([String])

    /// Filter reminders that do NOT have any of the specified tags (NOT logic).
    ///
    /// This is the inverse of `hasAnyTag`: excludes reminders that have at least one of the specified tags.
    ///
    /// - Parameter tags: The tags to exclude (without # prefix, case-insensitive).
    case notHasAnyTag([String])

    /// Filter reminders that have all of the specified tags (AND logic).
    ///
    /// - Parameter tags: The tags that must all be present (without # prefix, case-insensitive).
    case hasAllTags([String])

    /// Filter reminders that do NOT have all of the specified tags.
    ///
    /// This is the inverse of `hasAllTags`: includes reminders that are missing at least one of the specified tags.
    ///
    /// - Parameter tags: The tags (without # prefix, case-insensitive).
    case notHasAllTags([String])

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .none:
            hasher.combine(0)
        case .hasTag(let tag):
            hasher.combine(1)
            hasher.combine(tag.lowercased())
        case .notHasTag(let tag):
            hasher.combine(2)
            hasher.combine(tag.lowercased())
        case .hasAnyTag(let tags):
            hasher.combine(3)
            hasher.combine(tags.map { $0.lowercased() }.sorted())
        case .notHasAnyTag(let tags):
            hasher.combine(4)
            hasher.combine(tags.map { $0.lowercased() }.sorted())
        case .hasAllTags(let tags):
            hasher.combine(5)
            hasher.combine(tags.map { $0.lowercased() }.sorted())
        case .notHasAllTags(let tags):
            hasher.combine(6)
            hasher.combine(tags.map { $0.lowercased() }.sorted())
        }
    }

    public static func == (lhs: TagFilter, rhs: TagFilter) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (.hasTag(let lhsTag), .hasTag(let rhsTag)):
            return lhsTag.lowercased() == rhsTag.lowercased()
        case (.notHasTag(let lhsTag), .notHasTag(let rhsTag)):
            return lhsTag.lowercased() == rhsTag.lowercased()
        case (.hasAnyTag(let lhsTags), .hasAnyTag(let rhsTags)):
            return Set(lhsTags.map { $0.lowercased() }) == Set(rhsTags.map { $0.lowercased() })
        case (.notHasAnyTag(let lhsTags), .notHasAnyTag(let rhsTags)):
            return Set(lhsTags.map { $0.lowercased() }) == Set(rhsTags.map { $0.lowercased() })
        case (.hasAllTags(let lhsTags), .hasAllTags(let rhsTags)):
            return Set(lhsTags.map { $0.lowercased() }) == Set(rhsTags.map { $0.lowercased() })
        case (.notHasAllTags(let lhsTags), .notHasAllTags(let rhsTags)):
            return Set(lhsTags.map { $0.lowercased() }) == Set(rhsTags.map { $0.lowercased() })
        default:
            return false
        }
    }
}
