import Foundation
import SwiftUI

struct MPVMetalPlayerView: UIViewControllerRepresentable {
    let playUrl : URL?
    let coordinator = Coordinator()
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let mpv =  MPVMetalViewController()
        mpv.playUrl = playUrl
        
        context.coordinator.player = mpv
        return mpv
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }
    
    public func makeCoordinator() -> Coordinator {
        coordinator
    }
    
    public final class Coordinator: ObservableObject {
        weak var player: MPVMetalViewController?
        
        func play(_ url: URL) {
            player?.loadFile(url)
        }
    }
}
