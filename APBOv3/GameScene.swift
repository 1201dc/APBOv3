//
//  GameScene.swift
//  Zaptastic
//
//  Created by 90306670 on 9/9/20.
//  Copyright © 2020 Dhruv Chowdhary. All rights reserved.
//

import CoreMotion
import SpriteKit

enum CollisionType: UInt32 {
    case player = 1
    case playerWeapon = 2
    case enemy = 4
    case enemyWeapon = 8
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    let motionManager = CMMotionManager()
    let player = SKSpriteNode(imageNamed: "player")
    
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
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        setupLabels()
        if let particles = SKEmitterNode(fileNamed: "Starfield") {
            particles.position = CGPoint(x: 1080, y: 0)
            particles.advanceSimulationTime(60)
            particles.zPosition = -1
            addChild(particles)
        }
        
        player.name = "player"
        player.position.x = frame.minX+75
        player.zPosition = 1
        addChild(player)
        
        player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.texture!.size())
        player.physicsBody?.categoryBitMask = CollisionType.player.rawValue
        player.physicsBody?.collisionBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        player.physicsBody?.contactTestBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        player.physicsBody?.isDynamic = false
        
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
