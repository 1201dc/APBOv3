//
//  GameViewController.swift
//  Zaptastic
//
//  Created by 90306670 on 9/9/20.
//  Copyright © 2020 Dhruv Chowdhary. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            // Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "GameScene") {
                // Set the scale mode to scale to fit the window
                scene.scaleMode = .fill
                
                // Present the scene
                view.presentScene(scene)

            }
            
            view.ignoresSiblingOrder = true
            
            view.preferredFramesPerSecond = 120
            view.showsFPS = true
            view.showsNodeCount = true
            view.showsPhysics = true
            }
        }
    

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
