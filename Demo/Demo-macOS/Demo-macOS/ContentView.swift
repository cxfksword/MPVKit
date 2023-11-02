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
        NavigationSplitView {
            List {
                Button {
                    let url = URL(string: "https://vjs.zencdn.net/v/oceans.mp4")
                    player.coordinator.play(url!)
                } label: {
                    HStack {
                        Text("web url")
                        Spacer()
                    }
                }
                Button {
                    let url = Bundle.main.url(forResource: "subrip", withExtension: "mkv")
                    player.coordinator.play(url!)
                } label: {
                    HStack {
                        Text("subrip")
                        Spacer()
                    }
                }
                Button {
                    let url = Bundle.main.url(forResource: "rmvb", withExtension: "rm")
                    player.coordinator.play(url!)
                } label: {
                    HStack {
                        Text("rmvb")
                        Spacer()
                    }
                }
            }
        } detail: {
            player
        }
        .ignoresSafeArea()

    }
}
