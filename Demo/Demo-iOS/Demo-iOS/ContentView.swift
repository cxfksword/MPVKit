//
//  ContentView.swift
//  Demo
//
//  Created by cxf on 2023/8/5.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            MPVPlayerView(playUrl: URL(string: "https://vjs.zencdn.net/v/oceans.mp4")!)
        }
        .ignoresSafeArea()
    }
}
