//
//  GameScene.swift
//  CircleShooter
//
//  Created by Lai Phong Tran on 9/5/17.
//  Copyright © 2017 Lai Phong Tran. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    struct PhysicsCategory {
        static let none      : UInt32 = 0
        static let all       : UInt32 = UInt32.max
        static let floor     : UInt32 = 0b1
        static let box       : UInt32 = 0b10       // 1
        static let coin      : UInt32 = 0b11      // 2
    }
    
    var hueWheel = 0.00
    var onScreenCoinCount = 0 // not being used (originally intended to limit spawnBox if screen filled with coins)
    let floorNode = SKSpriteNode(imageNamed: "square")
    let coinAnimationScaleFactor : CGFloat = 5
    var touchLocation : CGPoint = CGPoint(x: 0, y: 0)
    var touchHolding : Bool = false
    
    private let hud = HudNode()
    
    override func didMove(to view: SKView) {
        // hud setup
        hud.setup(size: size)
        addChild(hud)
        // world setup
        backgroundColor = SKColor(hue: 0.6, saturation: 0.2, brightness: 0.1, alpha: 1)
        let border = SKPhysicsBody(edgeLoopFrom: self.frame)
        border.friction = 0
        border.restitution = 0.5//1.75//0.5
        self.physicsBody = border
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -5)
        physicsWorld.contactDelegate = self
        // floor setup
        floorNode.position = CGPoint(x: size.width / 2, y: 0)
        floorNode.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: -size.width / 2, y: 0), to: CGPoint(x: size.width, y: 0))
        floorNode.physicsBody?.isDynamic = true // 2
        floorNode.physicsBody?.affectedByGravity = false
        floorNode.physicsBody?.categoryBitMask = PhysicsCategory.floor
        floorNode.physicsBody?.contactTestBitMask = PhysicsCategory.coin
        floorNode.physicsBody?.collisionBitMask = PhysicsCategory.none // 5
        floorNode.physicsBody?.usesPreciseCollisionDetection = false
        addChild(floorNode)

        
        // gestures setup
        let downSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swipeAction(gesture:)))
        downSwipe.direction = .down
        view.addGestureRecognizer(downSwipe)

        let upSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swipeAction(gesture:)))
        upSwipe.direction = .up
        view.addGestureRecognizer(upSwipe)
        
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swipeAction(gesture:)))
        leftSwipe.direction = .left
        view.addGestureRecognizer(leftSwipe)
        
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swipeAction(gesture:)))
        rightSwipe.direction = .right
        view.addGestureRecognizer(rightSwipe)
        
        let touchHold = UILongPressGestureRecognizer(target: self, action: #selector(holdAction(gesture:)))
        view.addGestureRecognizer(touchHold)
        
        // box repeater
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(spawnBox),
                SKAction.wait(forDuration: 5)])))
    }
    
    @objc func swipeAction(gesture:UISwipeGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizer.Direction.down:
                if (floorNode.parent == nil) { // floorNode does not exist
                    addChild(floorNode)
                }
                print("score:", hud.score)
                print("down")
            case UISwipeGestureRecognizer.Direction.up:
                floorNode.removeFromParent()
                print("up")
            case UISwipeGestureRecognizer.Direction.left:
                spawnCoinColumn(dir: "left")
                print("left")
            case UISwipeGestureRecognizer.Direction.right:
                spawnCoinColumn(dir: "right")
                print("right")
            default: break
            }
        }
    }
    @objc func holdAction(gesture:UILongPressGestureRecognizer) {
        if touchHolding == false {
            coinExplosion(numberOfCoins: 10, location: touchLocation)
            touchHolding = true
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchHolding = false
        for touch in touches {
            touchLocation = touch.location(in: self)
            //let location = touch.location(in: self)
            spawnCoin(location: touch.location(in: self),
                      size: CGSize(width: 40 / coinAnimationScaleFactor, height: 40 / coinAnimationScaleFactor),
                      vector: nil,
                      color: nil)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            spawnCoin(location: touch.location(in: self), size: CGSize(width: 20 / coinAnimationScaleFactor, height: 20 / coinAnimationScaleFactor), vector: nil, color: SKColor.blue)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchHolding = false
    }
    
    //__________FUNCTIONS__________
    
    func spawnCoin(location: CGPoint, size: CGSize, vector: CGVector?, color: SKColor?) {
        let coin = SKSpriteNode(imageNamed: "boost_0")
        coin.position = location
        coin.size = size
        if color != nil {
            coin.color = color!
            coin.colorBlendFactor = 1
        } else {
            coin.colorBlendFactor = 0
        }
        coin.physicsBody?.affectedByGravity = true
        coin.physicsBody?.isDynamic = true
        coin.physicsBody?.categoryBitMask = PhysicsCategory.coin
        coin.physicsBody?.contactTestBitMask = PhysicsCategory.box | PhysicsCategory.floor
        coin.physicsBody?.collisionBitMask = PhysicsCategory.all
        coin.physicsBody?.usesPreciseCollisionDetection = true
        
        coin.physicsBody = SKPhysicsBody(circleOfRadius: coin.size.width * 0.35)
        addChild(coin)
        onScreenCoinCount += 1
        coin.physicsBody?.applyImpulse(vector ?? CGVector(dx: 0, dy: 0))
        coin.run(SKAction.scale(by: coinAnimationScaleFactor, duration: 0.1))
    }
    
    func spawnCoinColumn(dir: String) {
        for index in 1...5 {
            if dir == "left" {
                let coinColumnLocation = CGPoint(x: frame.width, y: frame.height - CGFloat(index * 75))
                spawnCoin(location: coinColumnLocation, size: CGSize(width: 40 / coinAnimationScaleFactor, height: 40 / coinAnimationScaleFactor), vector: CGVector(dx: -0.6, dy: 0), color: SKColor.green)
            } else if dir == "right" {
                let coinColumnLocation = CGPoint(x: 0, y: frame.height - CGFloat(index * 75))
                spawnCoin(location: coinColumnLocation, size: CGSize(width: 40 / coinAnimationScaleFactor, height: 40 / coinAnimationScaleFactor), vector: CGVector(dx: 0.6, dy: 0), color: SKColor.cyan)
            }
        }
    }

    func spawnBox() {
        let box = SKSpriteNode(imageNamed: "square")
        box.physicsBody = SKPhysicsBody(rectangleOf: box.size) // 1
        box.physicsBody?.isDynamic = true // 2
        box.physicsBody?.affectedByGravity = false
        box.physicsBody?.categoryBitMask = PhysicsCategory.box // 3
        box.physicsBody?.contactTestBitMask = PhysicsCategory.coin | PhysicsCategory.box // 4
        box.physicsBody?.collisionBitMask = PhysicsCategory.none // 5
        box.physicsBody?.usesPreciseCollisionDetection = false
        
        // random position with edge margin
        let actualX = random(min: box.size.width/2, max: size.width - box.size.width/2)
        let actualY = random(min: box.size.height/2, max: size.height - box.size.height/2)
        box.position = CGPoint(x: actualX, y: actualY)
        addChild(box)
        
        // Determine duration of existence
        let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
        // Create the actions
        let actionWait = SKAction.wait(forDuration: TimeInterval(actualDuration))
        let actionRemove = SKAction.removeFromParent()
        box.run(SKAction.sequence([SKAction.scale(to: 0, duration: 0),
                                     SKAction.scale(to: 1.5, duration: 0.1),
                                     SKAction.scale(to: 1, duration: 0.1),
                                     actionWait,
                                     SKAction.scale(to: 1.5, duration: 0.1),
                                     SKAction.scale(to: 0, duration: 0.1),
                                     actionRemove]))
    }

    func despawnCoin(node: SKSpriteNode) {
        node.removeFromParent()
        onScreenCoinCount -= 1
    }
    
    func coinExplosion(numberOfCoins: Int, location: CGPoint) {
        for i in 1...numberOfCoins {
            let degrees : Double = Double(360 / numberOfCoins * i)//(360 / Double(numberOfCoins)) * i
            let radians = degrees * Double.pi / Double(180)
            spawnCoin(location: location, size: CGSize(width: 40 / coinAnimationScaleFactor, height: 40 / coinAnimationScaleFactor), vector: CGVector(dx: cos(radians), dy: sin(radians)), color: SKColor.magenta)
        }
    }
    
    // MISC FUNCTIONS
    func boxOverlap(box2: SKSpriteNode) {
        box2.removeFromParent()
        spawnBox()
    }
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    // collisions
    func coinDidCollideWithBox(coin: SKSpriteNode, box: SKSpriteNode) {
        coinExplosion(numberOfCoins: 50, location: box.position)
        print("box hit")
        despawnCoin(node: coin)
        box.removeFromParent()
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        hueWheel += 0.01
    }
}

// collision detection
extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if ((firstBody.categoryBitMask & PhysicsCategory.box != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.coin != 0)) {
            if let box = firstBody.node as? SKSpriteNode,
                let coin = secondBody.node as? SKSpriteNode {
                coinDidCollideWithBox(coin: coin, box: box)
            }
        } else if ((firstBody.categoryBitMask & (PhysicsCategory.box ) != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.box != 0)) {
            if let box2 = firstBody.node as? SKSpriteNode {
                boxOverlap(box2: box2)
            }
        } else if ((firstBody.categoryBitMask & PhysicsCategory.floor != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.coin != 0)) {
            if let coin = secondBody.node as? SKSpriteNode {
                despawnCoin(node: coin)
                hud.addPoint()
            }
        }
    }
}
