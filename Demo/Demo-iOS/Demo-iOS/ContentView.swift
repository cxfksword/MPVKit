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
                            Text("h264")
                        }.frame(width: 100, height: 100)
                    }
                    Button {
                        player.coordinator.play(URL(string: "https://woolyss.com/f/hevc-aac-caminandes-2.mp4")!)
                    } label: {
                        VStack {
                            Text("h265")
                        }.frame(width: 100, height: 100)
                    }
                    Button {
                        player.coordinator.play(URL(string: "https://github.com/qiudaomao/MPVColorIssue/raw/master/MPVColorIssue/resources/captain.marvel.2019.2160p.uhd.bluray.x265-terminal.sample.mkv")!)
                    } label: {
                        VStack {
                            Text("HDR")
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
