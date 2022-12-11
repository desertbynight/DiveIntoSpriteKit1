//cfr https://github.com/ilyabelikin/DiveIntoSpriteKit/blob/master/Junkover/GameScene.swift


import SpriteKit
import CoreMotion

@objcMembers
class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let player = SKSpriteNode(imageNamed: "player-rocket.png")
    let motionManager = CMMotionManager()
    var gameTimer: Timer?
    let music = SKAudioNode(fileNamed: "cyborg-ninja")
    let scoreLabel = SKLabelNode(fontNamed: "AvenirNextCondensed-Bold")
    var score = 0 {
        didSet {
            scoreLabel.text = ("SCORE: \(score)")
        }
    }
    
    let enemies: [String] = ["space-junk", "asteroid", "enemy-ship"]
    let bonuses: [String] = ["star","energy"]
    
    let density : CGFloat = 0.7
   
    var index = 0

    var latestSprite: String {
        get {
            let value: String
            if index >= enemies.count + bonuses.count {
                // Reset the index if it has reached the end of the arrays
                index = 0
            }
            if index % 2 == 0 {
                value = enemies.randomElement()!
            } else {
                value = bonuses.randomElement()!
            }
            index += 1
            return value
        }
    }
    
    let playerCategory: UInt32 = 0x1 << 0 // 1
    let junkCategory: UInt32 = 0x1 << 1   // 2
    let bonusCategory: UInt32 = 0x1 << 2  // 4
     
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        
        addChild(music)
        
        score = 0
        scoreLabel.zPosition = 2
        scoreLabel.position.y = 300
        addChild(scoreLabel)

        let background = SKSpriteNode(imageNamed: "space.jpg")
        background.zPosition = -1
        addChild(background)
        
        if let particles = SKEmitterNode(fileNamed: "SpaceDust") {
            particles.position.x = 512
            particles.advanceSimulationTime(10)
            addChild(particles)
        }
        
        player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.size)
        player.physicsBody?.categoryBitMask = playerCategory
        player.physicsBody?.contactTestBitMask = playerCategory | junkCategory | bonusCategory
        player.physicsBody?.collisionBitMask = junkCategory
        player.physicsBody?.angularDamping = 0.25
        player.physicsBody?.density = density
        
        player.position.x = -400
        player.zPosition = 1
        
        addChild(player)
        
        motionManager.startAccelerometerUpdates()
        
        gameTimer = Timer.scheduledTimer(timeInterval: 0.35, target: self, selector: #selector(createSprite), userInfo: nil, repeats: true)
        
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // this method is called when the user touches the screen
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // this method is called when the user stops touching the screen
    }

    override func update(_ currentTime: TimeInterval) {
        if let accelerometerData = motionManager.accelerometerData {
            let changeX = CGFloat(accelerometerData.acceleration.y) * 100
            let changeY = CGFloat(accelerometerData.acceleration.x) * 100
            player.position.x -= changeX
            if player.position.x < -500 {
                player.position.x = -500
            }
            if player.position.x > 500 {
                player.position.x = 500
            }
            player.position.y += changeY
            if player.position.y < -340 {
                player.position.y = -340
            }
            if player.position.y > 340 {
                player.position.y = 340
            }
            if abs(changeX) + abs(changeY) <= 2 {
                if player.parent != nil {
                    score += 1
                }
            }
        }
        
        for node in children {
            if node.position.x <= -700
            {
                node.removeFromParent()
            }
        }
    }
    
    func createSprite() {
       let spriteName = latestSprite
        let sprite = SKSpriteNode(imageNamed: spriteName)
        sprite.position = CGPoint(x: 1200, y: Int.random(in: -350...350))
        sprite.name = spriteName
        sprite.zPosition = 1
        
        addChild(sprite)
        
        sprite.physicsBody = SKPhysicsBody(texture: sprite.texture!, size: sprite.size)
        sprite.physicsBody?.velocity = CGVector(dx: -500, dy: 0)
        sprite.physicsBody?.linearDamping = 0
        sprite.physicsBody?.contactTestBitMask = 1
        sprite.physicsBody?.categoryBitMask = 2
        sprite.physicsBody?.linearDamping = 0
        
        sprite.physicsBody?.collisionBitMask = playerCategory | junkCategory | bonusCategory
        
        if bonuses.contains(sprite.name!) {
            sprite.physicsBody?.density = 1
            sprite.physicsBody?.categoryBitMask = bonusCategory
            sprite.physicsBody?.contactTestBitMask = playerCategory | junkCategory | bonusCategory
            sprite.physicsBody?.collisionBitMask = junkCategory | bonusCategory
        } else {
            sprite.physicsBody?.density = density
            sprite.physicsBody?.categoryBitMask = junkCategory
            sprite.physicsBody?.contactTestBitMask = playerCategory | junkCategory | bonusCategory
        }

    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }

        if nodeA == player {
            playerHit(nodeB)
        } else {
            playerHit(nodeA)
        }
    }
    
    func playerHit(_ node: SKNode) {
        print("Hit by \(String(describing: node.name))!")
        if bonuses.contains(node.name!) {
            score += 1
            node.removeFromParent()
            return
        } else {
        
        player.removeFromParent()
        music.removeFromParent()
        let sound = SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false)
        run(sound)
        if let explosion = SKEmitterNode(fileNamed: "Explosion") {
            explosion.position = player.position
            explosion.zPosition = 3
            addChild(explosion)
        }
        let gameOver = SKSpriteNode(imageNamed: "gameOver-2")
        gameOver.zPosition = 10
        addChild(gameOver)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if let scene = GameScene(fileNamed: "GameScene") {
                scene.scaleMode = .aspectFill
                self.view?.presentScene(scene)
            }
        }
        }
            
    }
}

