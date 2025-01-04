//
// Created by Alexey Nenastev on 27.10.23.
// Copyright © 2023 Alexey Nenastyev (github.com/alexejn). All Rights Reserved.

import SwiftUI

struct ReloadButton: View {

  @State private var isReloadRotating = 0.0

  var isLoading: Bool
  var reload: () async -> Void

  var body: some View {
      Button(action: {
        Task {
          await reload()
        }
      }) {
      Image(systemName: "arrow.triangle.2.circlepath")
        .rotationEffect(.degrees(isReloadRotating))
    }
    .disabled(isLoading)
    .onAppear { animateIfNeed(isLoading: isLoading) }
    .onChange(of: isLoading, perform: { value in
      animateIfNeed(isLoading: value)
    })
  }

  private func animateIfNeed(isLoading: Bool) {
    if isLoading {
      withAnimation(.linear(duration: 3)
        .repeatForever(autoreverses: false)) {
          isReloadRotating = 360.0
        }
    } else {
      withAnimation(.linear(duration: 0)) {
        isReloadRotating = 0
      }
    }
  }
}
