import Foundation
import SwiftUI

struct MPVPlayerView: UIViewControllerRepresentable {
    let playUrl : URL?
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let mpv =  MPVViewController()
        mpv.playUrl = playUrl
        return mpv
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }
}
