//
// Created by Alexey Nenastev on 27.10.23.
// Copyright © 2023 Alexey Nenastyev (github.com/alexejn). All Rights Reserved.

import Foundation
import SwiftUI
import OSLog
import os

private extension View {
  func sheetDefaultSettings() -> some View {
    if #available(iOS 16.0, macOS 13.0, *) {
      return presentationDetents([.large])
    } else { return self }
  }
}

@available(iOS 15.0, macOS 11.0, *)
public struct LogView: View {

  @StateObject private var model: LogViewModel
  @State private var filterPresented = false
  @State private var selected: OSLogEntryLog?

  private func grouped(index: Int, items: [OSLogEntryLog]) -> Bool {
    let entry = items[index]
    var grouped = false
    if index > 0 && index < items.count - 1  {
      let prev = items[index+1]
      grouped = entry.subsystem == prev.subsystem &&
      entry.sender == prev.sender &&
      entry.category == prev.category
    }
    return grouped
  }

  public init(fetcher: @escaping (Date?) async throws -> [OSLogEntryLog], predicate: NSPredicate? = nil) {
    _model = .init(wrappedValue: LogViewModel(logViewFetcher: fetcher, logViewPredicate: predicate))
  }
  
  public var body: some View {
    Group {
      if case .failed(let error) = model.status {
        Text("Error: \(error.localizedDescription)")
              .lineLimit(nil)
              .padding()
      } else if model.status == .loading && model.logsIsEmpty {
        ProgressView()
      } else {
        ScrollView {
          LazyVStack(alignment: .leading) {
            let items = model.filteredAndSearched
            ForEach(items.indices.reversed(), id: \.self) { index in
              LogViewItem(log: items[index],
                          grouped: grouped(index: index, items: items),
                          onTap: { selected = $0 })

            }
          }
        }
        .refreshable {
          await model.load()
        }
      }
    }
    .sheet(item: $selected) { log in
      LogViewDetail(log: log)
        .environmentObject(model)
    }
    .sheet(isPresented: $filterPresented, content: {
      FilterView()
        .environmentObject(model)
        .sheetDefaultSettings()
    })
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          filterPresented.toggle()
        } label: {
          Image(systemName: model.filter != .empty ? "tag.fill" : "tag")
        }
        .disabled(model.status.isFailed)
      }

      ToolbarItem(placement: .destructiveAction) {
        Button {
          model.clear()
        } label: {
          Image(systemName: "trash")
        }
        .disabled(model.status.isFailed)
      }

      ToolbarItem(placement: .navigation) {
        Text("\(model.filteredAndSearched.count)")
          .fontWeight(.ultraLight)
      }

      ToolbarItem(placement: .primaryAction) {
        ReloadButton(isLoading: model.status == .loading, reload: model.load)
              .disabled(model.status.isFailed)
      }
    }
    .environmentObject(model)
    .searchable(text: $model.searchText, placement: .sidebar)
//    .navigationBarTitleDisplayMode(.inline)
  }
}

fileprivate extension View {
  func isReversed(_ value: Bool) -> some View {
    rotationEffect(value ? .radians(.pi) : .zero)
      .scaleEffect(x: value ? -1 : 1, y: 1, anchor: .center)
  }
}

@available(iOS 15.0, *)
extension OSLogEntryLog: @retroactive Identifiable {
  public var id: String {
    self.description
  }
}

@available(iOS 15.0, *)
struct LogsView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
        LogView(fetcher: { date in
            return []
        })
    }
  }
}

