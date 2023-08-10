import Foundation
import SwiftUI

struct MPVPlayerView: NSViewControllerRepresentable {
    let playUrl : URL?
    
    func makeNSViewController(context: Context) -> some NSViewController {
        let mpv =  MPVViewController()
        mpv.playUrl = playUrl
        return mpv
    }
    
    func updateNSViewController(_ nsViewController: NSViewControllerType, context: Context) {
        
    }
 
}

