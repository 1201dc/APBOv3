//
//  GameScene.swift
//  Zaptastic
//
//  Created by 90306670 on 9/9/20.
//  Copyright © 2020 Dhruv Chowdhary. All rights reserved.
//

import CoreMotion
import SpriteKit

let maxHealth = 100
let healthBarWidth: CGFloat = 40
let healthBarHeight: CGFloat = 4


enum CollisionType: UInt32 {
    case player = 1
    case playerWeapon = 2
    case enemy = 4
    case enemyWeapon = 8
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    let motionManager = CMMotionManager()
    let player = SKSpriteNode(imageNamed: "player")
    let turnButton = SKSpriteNode(imageNamed: "button")
    let shootButton = SKSpriteNode(imageNamed: "button")
    
    let thruster1 = SKEmitterNode(fileNamed: "Thrusters")
    
    let waves = Bundle.main.decode([Wave].self, from: "waves.json")
    let enemyTypes = Bundle.main.decode([EnemyType].self, from: "enemy-types.json")
    
    var isPlayerAlive = true
    var levelNumber = 0
    var waveNumber = 0
    var playerShields = 3
    
    var numAmmo = 20
    let ammo = SKLabelNode(text: "20")
    let ammoLabel = SKLabelNode(text: "Ammo")
    
    let points = SKLabelNode(text: "0")
    var numPoints = 0
    let pointsLabel = SKLabelNode(text: "Points")
    
    let health = SKLabelNode(text: "3")
    var numHealth = 3
    let healthLabel = SKLabelNode(text: "Lives")
    
    let playAgain = SKLabelNode(text: "Tap to Play Again")
    
    let positions = Array(stride(from: -320, through: 320, by: 80))
    
    
    override func didMove(to view: SKView) {
        
        size = view.bounds.size
           
           backgroundColor = SKColor(red: 14.0/255, green: 23.0/255, blue: 57.0/255, alpha: 1)
           
        
               
           physicsWorld.gravity = .zero
           physicsWorld.contactDelegate = self
           
           if let particles = SKEmitterNode(fileNamed: "Starfield") {
                   particles.position = CGPoint(x: frame.midX, y: frame.midY)
           //      particles.advanceSimulationTime(60)
                   particles.zPosition = -1
                   addChild(particles)
           }
        

        player.name = "apbo"
           player.position.x = size.width/2
             player.position.y = size.height/2
             player.zPosition = 1
        addChild(player)
        
        player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.texture!.size())
        player.physicsBody?.categoryBitMask = CollisionType.player.rawValue
        player.physicsBody?.collisionBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        player.physicsBody?.contactTestBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        player.physicsBody?.isDynamic = false
        
        
        turnButton.name = "btn"
        turnButton.size.height = 100
        turnButton.size.width = 100
        turnButton.zPosition = 2
        turnButton.position = CGPoint(x: self.frame.maxX-110,y: self.frame.minY+70)
        self.addChild(turnButton)
                
        shootButton.name = "shoot"
        shootButton.size.height = 100
        shootButton.size.width = 100
        shootButton.zPosition = 2
        shootButton.position = CGPoint(x: self.frame.minX+110 ,y: self.frame.minY+70)
        self.addChild(shootButton)
        

          thruster1?.zPosition = 1
        //  thruster1?.targetNode = self

         // player.addChild(thruster1!)
          addChild(thruster1!)
        
        
        motionManager.startAccelerometerUpdates()
    }
    
    func setupLabels() {
        points.position = CGPoint(x: frame.midX, y: frame.maxY*0.7)
        points.fontColor = UIColor.white
        points.fontSize = 80
        addChild(points)
        pointsLabel.position = CGPoint(x: frame.midX, y: frame.maxY*0.9)
        pointsLabel.fontColor = UIColor.white
        pointsLabel.fontSize = 40
        addChild(pointsLabel)
        
        health.position = CGPoint(x: frame.maxX*0.75, y: frame.maxY*0.7)
        health.fontColor = UIColor.red
        health.fontSize = 80
        addChild(health)
        
        healthLabel.position = CGPoint(x: frame.maxX*0.75, y: frame.maxY*0.9)
        healthLabel.fontColor = UIColor.red
        healthLabel.fontSize = 40
        addChild(healthLabel)
        
             ammo.position = CGPoint(x: frame.minX*0.75, y: frame.maxY*0.7)
             ammo.fontColor = UIColor.green
             ammo.fontSize = 80
             addChild(ammo)
        
        ammoLabel.position = CGPoint(x: frame.minX*0.75, y: frame.maxY*0.9)
        ammoLabel.fontColor = UIColor.green
        ammoLabel.fontSize = 40
        addChild(ammoLabel)
    }
    
    override func update(_ currentTime: TimeInterval) {
        if let accelerometerData = motionManager.accelerometerData {
            player.position.y += CGFloat(accelerometerData.acceleration.x * 50)
            
            if player.position.y < frame.minY + 20 {
                player.position.y = frame.minY + 20
            } else if player.position.y > frame.maxY-20 {
                player.position.y = frame.maxY - 20
            }
            
        }
        
        for child in children {
            if child.frame.maxX < 0 {
                if !frame.intersects(child.frame) {
                    child.removeFromParent()
                }
            }
        }
        
        let activeEnemies = children.compactMap { $0 as? EnemyNode }
        
        if activeEnemies.isEmpty {
            createWave()
        }
        
        for enemy in activeEnemies {
            guard frame.intersects(enemy.frame) else { continue }
            
            if enemy.lastFireTime + 1 < currentTime {
                enemy.lastFireTime = currentTime
                
                if Int.random(in: 0...2) == 0 || Int.random(in: 0...2) == 1 {
                    enemy.fire()
                }
            }
        }
    }
   
    
    func updateHealthBar(_ node: SKSpriteNode, withHealthPoints hp: Int) {
      let barSize = CGSize(width: healthBarWidth, height: healthBarHeight);
      
      let fillColor = UIColor(red: 113.0/255, green: 202.0/255, blue: 53.0/255, alpha:1)
      let borderColor = UIColor(red: 35.0/255, green: 28.0/255, blue: 40.0/255, alpha:1)
      
      // create drawing context
      UIGraphicsBeginImageContextWithOptions(barSize, false, 0)
      guard let context = UIGraphicsGetCurrentContext() else { return }
      
      // draw the outline for the health bar
      borderColor.setStroke()
      let borderRect = CGRect(origin: CGPoint.zero, size: barSize)
      context.stroke(borderRect, width: 1)
      
      // draw the health bar with a colored rectangle
      fillColor.setFill()
      let barWidth = (barSize.width - 1) * CGFloat(hp) / CGFloat(maxHealth)
      let barRect = CGRect(x: 0.5, y: 0.5, width: barWidth, height: barSize.height - 1)
      context.fill(barRect)
      
      // extract image
      guard let spriteImage = UIGraphicsGetImageFromCurrentImageContext() else { return }
      UIGraphicsEndImageContext()
      
      // set sprite texture and size
      node.texture = SKTexture(image: spriteImage)
      node.size = barSize
    }
    
    func createWave() {
        guard isPlayerAlive else { return }
        
        if waveNumber == waves.count {
            levelNumber += 1
            waveNumber = 0
        }
        
        let currentWave = waves[waveNumber]
        waveNumber += 1
        numAmmo = numAmmo + 5
        ammo.text = "\(numAmmo)"
        
        let maximumEnemyType = min(enemyTypes.count, levelNumber + 1)
        let enemyType = Int.random(in: 0..<maximumEnemyType)
        
        let enemyOffsetX: CGFloat = 100
        let enemyStartX = 600
        
        if currentWave.enemies.isEmpty {
            for(index, position) in positions.shuffled().enumerated() {
                let enemy = EnemyNode(type: enemyTypes[enemyType], startPosition: CGPoint(x: enemyStartX, y: position), xOffset: enemyOffsetX * CGFloat(index * 3), moveStright: true)
                addChild(enemy)
            }
        } else {
            for enemy in currentWave.enemies {
                let node = EnemyNode(type: enemyTypes[enemyType], startPosition: CGPoint(x: enemyStartX, y: positions[enemy.position]), xOffset: enemyOffsetX * enemy.xOffset, moveStright: enemy.moveStraight)
                addChild(node)
            }
        }
    }
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (!isPlayerAlive) {
           if let newScene = SKScene(fileNamed: "GameScene") {
            newScene.scaleMode = .fill
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            view?.presentScene(newScene, transition: reveal)
            }
        }
        guard isPlayerAlive else { return }
        guard !(numAmmo==0) else { return }
        let shot = SKSpriteNode(imageNamed: "playerWeapon")
        shot.name = "playerWeapon"
        shot.position = player.position
        shot.physicsBody = SKPhysicsBody(rectangleOf: shot.size)
        shot.physicsBody?.categoryBitMask = CollisionType.playerWeapon.rawValue
        shot.physicsBody?.collisionBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        shot.physicsBody?.contactTestBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        addChild(shot)
        numAmmo = numAmmo - 1
        ammo.text = "\(numAmmo)"
        
        let movement = SKAction.move(to: CGPoint(x: 1900, y: shot.position.y), duration: 5)
        let sequence = SKAction.sequence([movement, .removeFromParent()])
        shot.run(sequence)
        
    }
    
    
    func updatePlayer(_ dt: CFTimeInterval) {
        
        player.position = CGPoint(x:player.position.x + cos(player.zRotation) * 2.5 ,y:player.position.y + sin(player.zRotation) * 2.5)
       
        
        if player.position.y < frame.minY + 35 {
            player.position.y = frame.minY + 35
        } else if player.position.y > frame.maxY-35 {
            player.position.y = frame.maxY - 35
        }
        
        if player.position.x < frame.minX + 80 {
            player.position.x = frame.minX + 80
        } else if player.position.x > frame.maxX-80 {
            player.position.x = frame.maxX - 80

                    }
        
        thruster1?.position = CGPoint(x: (player.position.x ) + 30 * cos(-player.zRotation) , y:   (player.position.y) - 0 * sin(-player.zRotation) )

            
      //  thruster1?.zRotation = player.zRotation
        
    
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        
        let sortedNodes = [nodeA, nodeB].sorted { $0.name ?? "" < $1.name ?? "" }
        
        let firstNode = sortedNodes[0]
        let secondNode = sortedNodes[1]
        
        if secondNode.name == "player" {
            guard isPlayerAlive else { return }
            
            if let explosion = SKEmitterNode(fileNamed: "Explosion") {
                explosion.position = firstNode.position
                addChild(explosion)
            }
            
            playerShields -= 1
            numHealth -= 1
            health.text = "\(numHealth)"
            if playerShields == 0 {
                gameOver()
                secondNode.removeFromParent()
            }
            
            firstNode.removeFromParent()
        } else if let enemy = firstNode as? EnemyNode {
            enemy.shields -= 1
            
            if enemy.shields == 0 {
                if let explosion = SKEmitterNode(fileNamed: "Explosion") {
                    explosion.position = enemy.position
                    addChild(explosion)
                }
                
                enemy.removeFromParent()
                numPoints += enemy.scoreinc
                points.text = "\(numPoints)"
            }
            
            if let explosion = SKEmitterNode(fileNamed: "Explosion") {
                explosion.position = enemy.position
                addChild(explosion)
            }
            
            secondNode.removeFromParent()
        } else {
            if let explosion = SKEmitterNode(fileNamed: "Explosion") {
                explosion.position = secondNode.position
                addChild(explosion)
            }

            firstNode.removeFromParent()
            secondNode.removeFromParent()
        }
    }
    
    
    func gameOver() {
        isPlayerAlive = false
        playAgain.position = CGPoint(x: frame.midX, y: frame.midY - 140)
        playAgain.fontColor = UIColor.white
        playAgain.fontSize = 60
        addChild(playAgain)
        
        if let explosion = SKEmitterNode(fileNamed: "Explosion") {
            explosion.position = player.position
            addChild(explosion)
        }
        
        let gameOver = SKSpriteNode(imageNamed: "gameOver")
            addChild(gameOver)


    }
}
