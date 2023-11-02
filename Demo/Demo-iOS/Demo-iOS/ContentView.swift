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
                        let url = URL(string: "https://vjs.zencdn.net/v/oceans.mp4")
                        player.coordinator.play(url!)
                    } label: {
                        VStack {
                            Text("web url")
                        }.frame(width: 100, height: 100)
                    }
                    Button {
                        let url = Bundle.main.url(forResource: "subrip", withExtension: "mkv")
                        player.coordinator.play(url!)
                    } label: {
                        VStack {
                            Text("subrip")
                        }.frame(width: 100, height: 100)
                    }
                    Button {
                        let url = Bundle.main.url(forResource: "rmvb", withExtension: "rm")
                        player.coordinator.play(url!)
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
