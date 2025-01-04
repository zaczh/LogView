//
// Created by Alexey Nenastev on 27.10.23.
// Copyright © 2023 Alexey Nenastyev (github.com/alexejn). All Rights Reserved.

import Foundation
import SwiftUI
import OSLog
import Combine
import os

private let logger = Logger(subsystem: "com.logview", category: "logger")

@available(iOS 15.0, *)
final class LogViewModel: ObservableObject {
    enum Status: Equatable {
        static func == (lhs: LogViewModel.Status, rhs: LogViewModel.Status) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading):
                return true
            case (.loaded, .loaded):
                return true
            case (.failed, .failed):
                return true
            case (_, _):
                return false
            }
        }
        
        case loading
        case loaded
        case failed(Error)
    }
    
  private var logs: [OSLogEntryLog] = [] {
    didSet {
      var stat = LogFilter.TagsStatistic()
      filtered = filter.filter(entries: logs, statistic: &stat)
      filterStatistic = stat
    }
  }

  var logsIsEmpty: Bool {
    logs.isEmpty
  }

  private var logViewFetcher: (Date?) throws -> [OSLogEntry]
  private var logViewPredicate: NSPredicate?
  private var logViewFilter: LogView.FilterEntries
  @Published var filtered: [OSLogEntryLog] = []
  @Published var filterStatistic = LogFilter.TagsStatistic()
    
  @Published var status: LogViewModel.Status = .loading
  @Published var searchText: String = ""

  var filteredAndSearched: [OSLogEntryLog] {
    filtered.filter { log in
      searchText.isEmpty || log.composedMessage.lowercased().contains(searchText.lowercased())
    }
  }

  private var lastDate: Date?

  @Published var filter: LogFilter = .empty {
    didSet {
      var stat = LogFilter.TagsStatistic()
      filtered = filter.filter(entries: logs, statistic: &stat)
      filterStatistic = stat
    }
  }

  init(logViewFetcher: @escaping (Date?) throws -> [OSLogEntry], logViewPredicate: NSPredicate? = nil, logViewFilter: @escaping LogView.FilterEntries = { _ in true }) {
    self.logViewFetcher = logViewFetcher
    self.logViewPredicate = logViewPredicate
    self.logViewFilter = logViewFilter
    load()
  }

  nonisolated private func fetchLogs() async {
    do {
        
      let entries = try logViewFetcher(lastDate)

      let filteredEntries = entries.compactMap { entry -> OSLogEntryLog? in
        guard let log = entry as? OSLogEntryLog, 
                log.date.timeIntervalSince1970 > (lastDate?.timeIntervalSince1970 ?? 0 ),
                logViewPredicate?.evaluate(with: log) != false,
              logViewFilter(log) else { return nil }
        return log
      }

      for log in filteredEntries {
        LogFilter.all.categories.insert(log.category)
        LogFilter.all.sybsytems.insert(log.subsystem)
        LogFilter.all.levels.insert(log.level.rawValue)
        LogFilter.all.senders.insert(log.sender)
      }

      Task { @MainActor in
        self.logs.append(contentsOf: filteredEntries)
          self.status = .loaded
        self.lastDate = self.logs.last?.date
      }
    } catch {
      logger.error("Can't fetch entries: \(error)")
        Task { @MainActor in
          self.status = .failed(error)
        }
    }
  }

  func load() {
    Task { @MainActor in
      status = .loading
    }
    Task {
      await self.fetchLogs()
    }
  }

  func clear() {
    logs = []
  }
}

@available(iOS 15.0, *)
extension Date {
  var logTimeString: String {
    formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute().second().secondFraction(.fractional(3)))
  }
}

extension Sequence {
  func uniqueMap<K: Hashable>(_ kp: KeyPath<Element, K>) -> Set<K> {
    let mapped = map { $0[keyPath: kp]}
    return Set(mapped)
  }
}

extension Sequence {
  func uniqueMap(_ kp: KeyPath<Element, String>) -> Set<String> {
    let mapped = map { $0[keyPath: kp] }
    return Set(mapped.filter { $0 != "" })
  }
}

@available(iOS 15.0, *)
extension OSLogEntryLog.Level {
  var description: String {
    switch self {
    case .debug: return "debug"
    case .info: return "info"
    case .notice: return "notice"
    case .error: return "error"
    case .fault: return "fault"
    default: return ""
    }
  }

  var color: Color {
    switch self {
    case .debug: return .gray
    case .info: return .blue
    case .notice: return .mint
    case .error: return .red
    case .fault: return .black
    default: return .gray
    }
  }
}
