import Foundation
import SwiftUI

struct MPVMetalPlayerView: NSViewControllerRepresentable {
    let playUrl : URL?
    let coordinator = Coordinator()
    
    func makeNSViewController(context: Context) -> some NSViewController {
        let mpv =  MPVMetalViewController()
        mpv.playUrl = playUrl
        
        context.coordinator.player = mpv
        return mpv
    }
    
    func updateNSViewController(_ nsViewController: NSViewControllerType, context: Context) {
        
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

