//
//  GameViewController.swift
//  peerdoku
//
//  Created by Vincent Ooi on 11/20/24.
//

import UIKit
import SpriteKit
import GameKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup game immediately
        setupGame()
        
        // Initialize Game Center in the background
        initializeGameCenter { success in
            if success {
                print("Game Center authentication successful")
            } else {
                print("Game Center authentication failed - game will continue without leaderboards")
            }
        }
    }
    
    private func initializeGameCenter(completion: @escaping (Bool) -> Void) {
        let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = { [weak self] viewController, error in
            DispatchQueue.main.async {
                if let viewController = viewController {
                    self?.present(viewController, animated: true)
                } else if error != nil {
                    print("Game Center authentication error: \(error?.localizedDescription ?? "Unknown error")")
                    completion(false)
                } else {
                    GameCenterManager.shared.isAuthenticated = localPlayer.isAuthenticated
                    completion(localPlayer.isAuthenticated)
                }
            }
        }
    }
    
    private func setupGame() {
        if let view = self.view as! SKView? {
            let scene = GameScene(size: view.bounds.size)
            scene.scaleMode = .aspectFill
            
            view.presentScene(scene)
            view.ignoresSiblingOrder = true
            
            #if DEBUG
            view.showsFPS = true
            view.showsNodeCount = true
            #endif
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
