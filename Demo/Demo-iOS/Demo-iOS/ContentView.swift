//
//  ContentView.swift
//  Demo
//
//  Created by cxf on 2023/8/5.
//

import SwiftUI

struct ContentView: View {
    let player : MPVPlayerView!
    
    init() {
        player = MPVPlayerView(playUrl: URL(string: "https://vjs.zencdn.net/v/oceans.mp4")!)
    }
    
    
    var body: some View {
        VStack {
            player.frame(height: 400)
            
            ScrollView(.horizontal) {
                HStack {
                    Button {
                        player.coordinator.play(URL(string: "https://vjs.zencdn.net/v/oceans.mp4")!)
                    } label: {
                        VStack {
                            Text("web url")
                        }.frame(width: 100, height: 100)
                    }
                    Button {
                        player.coordinator.play(URL(string: "https://github.com/cxfksword/video-test/raw/master/resources/subrip.mkv")!)
                    } label: {
                        VStack {
                            Text("subrip")
                        }.frame(width: 100, height: 100)
                    }
                    Button {
                        player.coordinator.play(URL(string: "https://github.com/cxfksword/video-test/raw/master/resources/rmvb.rm")!)
                    } label: {
                        VStack {
                            Text("rmvb")
                        }.frame(width: 100, height: 100)
                    }
                }
            }
            
            Spacer()
        }
    }
}
