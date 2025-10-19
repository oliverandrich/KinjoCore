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

/// Represents a text annotation for a portion of the parsed input.
///
/// Annotations map specific parts of the original input string to their
/// parsed meaning, enabling UI implementations to highlight which parts
/// of the input correspond to which task properties.
///
/// ## Example Usage
///
/// ```swift
/// let input = "Meeting morgen 14:00 p1 @Arbeit"
/// let task = parser.parse(input)
///
/// for annotation in task.annotations {
///     switch annotation.type {
///     case .scheduledDate:
///         highlightText(annotation.text, color: .blue)  // "morgen"
///     case .time:
///         highlightText(annotation.text, color: .green)  // "14:00"
///     case .priority:
///         highlightText(annotation.text, color: .red)    // "p1"
///     case .project:
///         highlightText(annotation.text, color: .purple) // "@Arbeit"
///     default:
///         break
///     }
/// }
/// ```
public struct Annotation: Sendable, Equatable {

    // MARK: - Annotation Type

    /// The type of annotation, indicating what kind of information was recognised.
    public enum AnnotationType: String, Sendable, Equatable {
        /// A scheduled date (when to work on it).
        case scheduledDate

        /// A deadline (when it must be completed).
        case deadline

        /// A time component.
        case time

        /// A priority marker (p1-4 or !!!-!).
        case priority

        /// A project tag (@-tag).
        case project

        /// A label/tag (#-tag).
        case label

        /// A recurrence pattern keyword.
        case recurring
    }

    // MARK: - Properties

    /// The range in the original input string where this annotation applies.
    public let range: Range<String.Index>

    /// The text that was matched for this annotation.
    ///
    /// For example, "morgen" for a scheduled date, "p1" for priority,
    /// or "@Arbeit" for a project.
    public let text: String

    /// The type of this annotation.
    public let type: AnnotationType

    // MARK: - Initialisation

    /// Creates a new annotation.
    ///
    /// - Parameters:
    ///   - range: The range in the original input string.
    ///   - text: The text that was matched.
    ///   - type: The type of annotation.
    public init(
        range: Range<String.Index>,
        text: String,
        type: AnnotationType
    ) {
        self.range = range
        self.text = text
        self.type = type
    }
}
