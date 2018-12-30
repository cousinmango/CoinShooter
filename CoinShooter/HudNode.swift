//
//  HudNode.swift
//  CoinShooter
//
//  Created by Lai Phong Tran on 30/12/18.
//  Copyright © 2018 Lai Phong Tran. All rights reserved.
//

import Foundation
import SpriteKit

class HudNode : SKNode {
    private let scoreKey = "CURRENT_SCORE"
    private let scoreNode = SKLabelNode(fontNamed: "Helvetica")
    private(set) var score : Int = 0
    
    //Setup hud here
    public func setup(size: CGSize) {
        let defaults = UserDefaults.standard
        
        score = defaults.integer(forKey: scoreKey)
        
        scoreNode.text = "\(score)"
        scoreNode.fontSize = 70
        scoreNode.position = CGPoint(x: size.width / 2, y: size.height - 100)
        scoreNode.zPosition = 1
        
        addChild(scoreNode)
    }
    
    public func addPoint() {
        score += 1
        updateScore()
        let defaults = UserDefaults.standard
        defaults.set(score, forKey: scoreKey)
    }
    
    private func updateScore() {
        scoreNode.text = "\(score)"
    }
}
