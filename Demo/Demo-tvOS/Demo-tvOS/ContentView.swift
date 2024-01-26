import SwiftUI

struct ContentView: View {
    let player : MPVMetalPlayerView!
    
    init() {
        player = MPVMetalPlayerView(playUrl: URL(string: "https://github.com/haasn/hdr-tests/raw/master/colorbars.mp4")!)
    }
    
    
    var body: some View {
        VStack {
            player
        }
        .overlay {
            VStack {
                Spacer()
                HStack(alignment: .center) {
                    Button {
                        player.coordinator.play(URL(string: "https://vjs.zencdn.net/v/oceans.mp4")!)
                    } label: {
                        VStack {
                            Text("h264")
                        }.frame(width: 100, height: 100)
                    }
                    Button {
                        player.coordinator.play(URL(string: "https://github.com/cxfksword/video-test/raw/master/resources/h265.mp4")!)
                    } label: {
                        VStack {
                            Text("h265")
                        }.frame(width: 130, height: 100)
                    }
                    Button {
                        player.coordinator.play(URL(string: "https://github.com/cxfksword/video-test/raw/master/resources/hdr.mkv")!)
                    } label: {
                        VStack {
                            Text("HDR")
                        }.frame(width: 130, height: 100)
                    }
                    Button {
                        player.coordinator.play(URL(string: "https://github.com/cxfksword/video-test/raw/master/resources/pgs_subtitle.mkv")!)
                    } label: {
                        VStack {
                            Text("subtitle")
                        }.frame(width: 130, height: 100)
                    }
                    Button {
                        player.coordinator.play(URL(string: "https://github.com/cxfksword/video-test/raw/master/resources/rmvb.rm")!)
                    } label: {
                        VStack {
                            Text("rmvb")
                        }.frame(width: 130, height: 100)
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }
}
