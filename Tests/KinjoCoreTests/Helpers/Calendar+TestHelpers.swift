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
import CoreGraphics
@testable import KinjoCore

extension KinjoCore.Calendar {
    /// Creates a test calendar without requiring EventKit.
    ///
    /// This initialiser is only for use in tests and creates a Calendar
    /// directly using the internal test initialiser, avoiding any EventKit dependencies.
    ///
    /// - Parameters:
    ///   - id: The unique identifier for this calendar.
    ///   - title: The display title of the calendar.
    ///   - colour: The colour associated with this calendar.
    ///   - sourceName: The source name (e.g., "iCloud", "Local") of this calendar.
    ///   - sourceID: The source identifier for this calendar.
    ///   - isImmutable: Whether this calendar is immutable (read-only).
    ///   - isSubscribed: Whether this calendar is subscribed.
    static func makeTest(
        id: String = UUID().uuidString,
        title: String,
        colour: CGColor = CGColor(gray: 0.5, alpha: 1.0),
        sourceName: String = "Test Source",
        sourceID: String = "test-source",
        isImmutable: Bool = false,
        isSubscribed: Bool = false
    ) -> KinjoCore.Calendar {
        // Use the internal test initialiser directly
        return KinjoCore.Calendar(
            id: id,
            title: title,
            colour: colour,
            sourceName: sourceName,
            sourceID: sourceID,
            isImmutable: isImmutable,
            isSubscribed: isSubscribed
        )
    }
}
