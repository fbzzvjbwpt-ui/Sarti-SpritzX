//
//  ContentView.swift
//  Sarti SpritzX
//
//  Created by Tobias Thiele on 12.09.26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.yellow
                .ignoresSafeArea()
            Text("Willkommen")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    ContentView()
}
