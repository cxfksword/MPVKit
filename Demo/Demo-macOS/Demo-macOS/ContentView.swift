//
//  ContentView.swift
//  Demo-macOS
//
//  Created by cxf on 2023/8/7.
//

import SwiftUI

struct ContentView: View {
    let player : MPVPlayerView!
    
    init() {
        player = MPVPlayerView(playUrl: URL(string: "https://vjs.zencdn.net/v/oceans.mp4")!)
    }
    var body: some View {
        VStack {
            player
        }
        .ignoresSafeArea()

    }
}
