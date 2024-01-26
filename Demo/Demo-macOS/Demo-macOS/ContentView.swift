import SwiftUI

struct ContentView: View {
    let player : MPVMetalPlayerView!
    
    init() {
        player = MPVMetalPlayerView(playUrl: URL(string: "https://github.com/haasn/hdr-tests/raw/master/colorbars.mp4")!)
    }
    
    var body: some View {
        NavigationSplitView {
            List {
                Button {
                    player.coordinator.play(URL(string: "https://vjs.zencdn.net/v/oceans.mp4")!)
                } label: {
                    HStack {
                        Text("h264")
                        Spacer()
                    }
                }
                Button {
                    player.coordinator.play(URL(string: "https://github.com/cxfksword/video-test/raw/master/resources/h265.mp4")!)
                } label: {
                    HStack {
                        Text("h265")
                        Spacer()
                    }
                }
                Button {
                    player.coordinator.play(URL(string: "https://github.com/cxfksword/video-test/raw/master/resources/hdr.mkv")!)
                } label: {
                    HStack {
                        Text("HDR")
                        Spacer()
                    }
                }
                Button {
                    player.coordinator.play(URL(string: "https://github.com/cxfksword/video-test/raw/master/resources/pgs_subtitle.mkv")!)
                } label: {
                    HStack {
                        Text("subtitle")
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
