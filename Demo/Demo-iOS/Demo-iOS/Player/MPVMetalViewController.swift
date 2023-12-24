//
//  MPVMetalViewController.swift
//  Demo-iOS
//
//  Created by cxf on 2023/12/24.
//

import Foundation
import UIKit

final class MPVMetalViewController: UIViewController {
    var playUrl: URL?
    var client:MPVClient!
    
    override func viewDidLoad() {
        super.loadView()
        self.client = MPVClient()
        client.create(frame: view.frame)
        view.layer.addSublayer(client.metalLayer)
        super.viewDidLoad()
    }
    
    func loadFile(
        _ url: URL
    ) {
        client.loadFile(url)
    }
}
