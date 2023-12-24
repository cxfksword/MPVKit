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
                    player.coordinator.play(URL(string: "https://vjs.zencdn.net/v/oceans.mp4")!)
                } label: {
                    HStack {
                        Text("web url")
                        Spacer()
                    }
                }
                Button {
                    player.coordinator.play(URL(string: "https://github.com/cxfksword/video-test/raw/master/resources/subrip.mkv")!)
                } label: {
                    HStack {
                        Text("subrip")
                        Spacer()
                    }
                }
                Button {
                    player.coordinator.play(URL(string: "https://github.com/cxfksword/video-test/raw/master/resources/rmvb.rm")!)
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
