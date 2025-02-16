//
// Created by Alexey Nenastev on 27.10.23.
// Copyright © 2023 Alexey Nenastyev (github.com/alexejn). All Rights Reserved.

import Foundation
import SwiftUI
import OSLog

@available(iOS 15.0, *)
struct FilterView: View {
  @EnvironmentObject var model: LogViewModel

  @State var tagButtonAction: TagButtonAction = .equal

  @ViewBuilder
  private func section<T: Comparable>(_ title: String,
                                      _ tagsKp: WritableKeyPath<LogFilter.Tags, Set<T>>,
                                      systemName: String,
                                      @ViewBuilder button: @escaping (T) -> some View) -> some View {
    HStack {
      Image(systemName: systemName)
      Text(title)
        .font(.title2)
    }
    let values = LogFilter.all[keyPath: tagsKp]
    VFlow(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
      ForEach(values.sorted(), id: \.self) {
        button($0)
      }
    }
  }

  var body: some View {
    VStack(alignment: .leading) {
      HStack(spacing: 15) {
        TagButtonActionPicker(tagButtonAction: $tagButtonAction)
        Divider()
          .frame(height: 20)
        Button {
          model.filter.equals = .init()
          model.filter.notEquals = .init()
        } label: {
          Text("Clear")
        }
        .buttonStyle(.bordered)
      }
        .padding()
      Divider()
      ScrollView {
        VStack(alignment: .leading) {
          section("Log level", \.levels, systemName: "stethoscope") {
            TagButton.level(tag: $0)
          }
          section("Subsystem", \.sybsytems, systemName: "gearshape.2") {
            TagButton.subsystem(tag: $0)
          }
          section("Category", \.categories, systemName: "square.grid.3x3") {
            TagButton.category(tag: $0)
          }
          section("Library", \.senders, systemName: "building.columns") {
            TagButton.sender(tag: $0)
          }
        }
        .environment(\.tagButtonAction, tagButtonAction)
        .padding()
      }
    }
  }
}

@available(iOS 15.0, *)
struct FilterView_Previews: PreviewProvider {
  struct Preview: View {
      @StateObject var model = LogViewModel(logViewFetcher: { date in
          return []
      })

    var body: some View {
      model.filterStatistic = LogFilter.TagsStatistic(levels: [2: 2])
      return NavigationView {
        FilterView()
        .environmentObject(model)
      }
    }
  }
  static var previews: some View {
    LogFilter.all.categories = ["auth", "data", "ui", "networking"]
    LogFilter.all.sybsytems = ["com.apple.uikit", "com.apple.dt", "com.fbs.test"]
    LogFilter.all.levels = .all
    LogFilter.all.senders = ["fbsData", "fbsUI", "Networking", "Firebase"]

    return Preview()
  }
}
