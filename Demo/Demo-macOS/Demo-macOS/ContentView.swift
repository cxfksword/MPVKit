import SwiftUI

struct ContentView: View {
    let player : MPVPlayerView!
    
    init() {
        player = MPVPlayerView(playUrl: URL(string: "https://woolyss.com/f/hevc-aac-caminandes-2.mp4")!)
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
                    player.coordinator.play(URL(string: "https://woolyss.com/f/hevc-aac-caminandes-2.mp4")!)
                } label: {
                    HStack {
                        Text("h265")
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
