//
// Created by Alexey Nenastev on 27.10.23.
// Copyright © 2023 Alexey Nenastyev (github.com/alexejn). All Rights Reserved.

import Foundation
import OSLog

@available(iOS 15.0, *)
extension LogView {

  public typealias FilterEntries = (OSLogEntryLog) -> Bool
}

public extension NSPredicate {
  /// Predicate for fetching from OSLogStore, allow to condition subsystem, and set if empty subsystem should be filtered.
  static func subystemIn(_ values: [String], orNil: Bool = true) -> NSPredicate {
    NSPredicate(format: "\(orNil ? "subsystem == nil OR" : "") subsystem in $LIST")
      .withSubstitutionVariables(["LIST" : values])
  }
}
