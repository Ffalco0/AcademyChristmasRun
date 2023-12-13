//
//  GameScene.swift
//  TestShitty
//
//  Created by Fabio Falco on 12/12/23.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    struct PhysicsCategory{
        static let Player:      UInt32 = 0b1
        static let Obstacle:       UInt32 = 0b10
        static let Ground:      UInt32 = 0b100
    }
    
    //Elements
    var floor:SKSpriteNode!
    var player:SKSpriteNode!
    var bg:SKSpriteNode!
    var obstacleTypes:[String] = ["block-1","block-2","block-3","obstacle-1","obstacle-2"]
    
    
    //Stats
    var velocity:CGFloat = 7.0//Change this value to modify yhe movement speed
    
    
    var startTouch = CGPoint()
    var endTouch = CGPoint()
    var onGround:Bool = true
    
    var obstacleSpawnTimer: Timer?
    
    //Pause Element
    var gamePaused = false
    var pauseMenu: SKSpriteNode?
    
    //Score element
    var scoreLabel = SKLabelNode(fontNamed:"Chalkduster")
    var numScore:Int = 0
    
    //Music
    var backgrounMusic:SKAudioNode?
    
    override func didMove(to view: SKView) {
        //Setup scene
        self.anchorPoint = .zero
        backgroundColor = .lightGray
        physicsWorld.contactDelegate = self
        playBackgroundMusic()
        
        
        setUpNodes()
        createGround()
        
        startObstacleSpawnTimer()
        
        //Create a pause menu
        pauseMenu = SKSpriteNode(imageNamed: "panel")
        pauseMenu?.position = CGPoint(x: size.width / 2, y: size.height / 2)
        pauseMenu?.isHidden = true
        addChild(pauseMenu!)
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        moveGrounds()
        moveBg()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let touch = touches.first{
            let location = touch.location(in: self)
            if self.nodes(at: location).first(where: { $0.name == "pause" }) != nil {
                togglePause()
            }else{
                let normalizedIntensity = min(max(location.y / size.height, 0.0), 1.0)
                let jumpIntensity = normalizedIntensity * 1000.0 //Change the coefficient for a higher jump
                if !gamePaused{
                    if onGround{
                        addPoints()
                        playerJump(withIntensity: jumpIntensity)
                    }
                }
            }
        }
    }
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        
        if (bodyA.categoryBitMask == PhysicsCategory.Player && bodyB.categoryBitMask == PhysicsCategory.Ground) ||
            (bodyA.categoryBitMask == PhysicsCategory.Ground && bodyB.categoryBitMask == PhysicsCategory.Player) {
            // Il giocatore ha toccato un ostacolo, esegui la logica desiderata
            onGround = true
        }
        if (bodyA.categoryBitMask == PhysicsCategory.Player && bodyB.categoryBitMask == PhysicsCategory.Obstacle) ||
            (bodyA.categoryBitMask == PhysicsCategory.Obstacle && bodyB.categoryBitMask == PhysicsCategory.Player) {
            // Il giocatore ha toccato un ostacolo, esegui la logica desiderata
            print("GameOver")
        }
    }
}

extension GameScene{
    func setUpNodes(){
        createBg()
        setupPause()
        createPlayer()
        setupScore()
    }
    
    func createBg(){
        for i in 0...1{
            bg = SKSpriteNode(imageNamed: "Bg\(i)")
            bg.name = "BG"
            bg.setScale( 0.9)
            bg.anchorPoint = .zero
            bg.position = CGPoint(x: CGFloat(i) * bg.size.width, y: 0.0)
            bg.zPosition = -1.0
            self.addChild(bg)
        }
    }
    
    func createGround(){
        for i in 0...3{
            floor = SKSpriteNode(imageNamed: "floor")
            floor.name = "floor"
            //floor.size = CGSize(width: (self.scene?.size.width)!, height: 250)
            floor.anchorPoint = .zero
            floor.zPosition = 4.0
            floor.position = CGPoint(x: CGFloat(i) * floor.size.width,
                                     y: floor.size.height / 1.5)
            
            floor.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: floor.size.width,
                                                                  height:floor.size.height))
            floor.physicsBody?.affectedByGravity = false
            floor.physicsBody?.isDynamic = false
            floor.physicsBody?.categoryBitMask = PhysicsCategory.Ground
            floor.physicsBody?.contactTestBitMask = PhysicsCategory.Player
            
            self.addChild(floor)
        }
    }
    
    func moveGrounds(){
        self.enumerateChildNodes(withName: "floor", using: ({
            (node,error) in
            
            node.position.x -= self.velocity
            
            if node.position.x < -(self.scene?.size.width)!{
                node.position.x += (self.scene?.size.width)! * 3
            }
        }))
    }
    func moveBg(){
        self.enumerateChildNodes(withName: "BG", using: ({
            (node,error) in
            
            node.position.x -= self.velocity
            
            if node.position.x < -(self.scene?.size.width)!{
                node.position.x += (self.scene?.size.width)! * 3
            }
        }))
    }
    
    func createPlayer(){
        player = SKSpriteNode(imageNamed: "00_Run")
        //Run animation
        
        var textures:[SKTexture] = []
        for i in 0...8{
            textures.append(SKTexture(imageNamed: "0\(i)_Run"))
        }
        player.run(.repeatForever(.animate(with: textures, timePerFrame: 0.08)))
        
        player.setScale(4.0)
        player.position = CGPoint(x: frame.midX/2.0,
                                  y: frame.midY)
        player.zPosition = 5.0
        player.physicsBody = SKPhysicsBody(circleOfRadius: self.player.size.width/3.5)
        player.physicsBody?.affectedByGravity = true
        player.physicsBody?.isDynamic = true
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.categoryBitMask = PhysicsCategory.Player
        player.physicsBody?.contactTestBitMask = PhysicsCategory.Ground | PhysicsCategory.Obstacle
        self.addChild(player)
    }
    
    func playerJump(withIntensity intensity:CGFloat){
        player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: intensity))
        onGround = false
        //animazione jump
        var jumpPlayer: [SKTexture] = []
        for i in 0...2{
            jumpPlayer.append(SKTexture(imageNamed: "0\(i)_Jump"))
        }
        player.run(.repeat(.animate(with: jumpPlayer, timePerFrame: 0.4), count: 1))
    }
    
    //Gestiamo gli ostacoli
    func startObstacleSpawnTimer() {
        obstacleSpawnTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(spawnObstacle), userInfo: nil, repeats: true)
    }
    
    
    @objc func spawnObstacle() {
        guard let randomObstacleType = obstacleTypes.randomElement() else { return }
        
        let obstacle = SKSpriteNode(imageNamed: randomObstacleType)
        obstacle.position = CGPoint(x: size.width + obstacle.size.width * 2.5, y: size.height / 2)
        obstacle.zPosition = 5.0
        obstacle.setScale(0.45)
        obstacle.physicsBody = SKPhysicsBody(rectangleOf: obstacle.size)
        obstacle.physicsBody?.affectedByGravity = true
        obstacle.physicsBody?.isDynamic = true
        obstacle.physicsBody?.allowsRotation = false
        obstacle.physicsBody?.categoryBitMask = PhysicsCategory.Obstacle
        obstacle.physicsBody?.contactTestBitMask = PhysicsCategory.Player
        
        addChild(obstacle)
        
        let moveAction = SKAction.moveTo(x: -obstacle.size.width, duration: 3)
        let removeAction = SKAction.removeFromParent()
        obstacle.run(SKAction.sequence([moveAction, removeAction]))
    }
    
    
    //Function that handle the pause
    func togglePause() {
        gamePaused = !gamePaused
        
        //Handle music during pause
        if gamePaused {
            backgrounMusic?.run(SKAction.pause())
        } else {
            backgrounMusic?.run(SKAction.play())
        }
        
        // Metti in pausa o riprendi la scena e il timer degli ostacoli
        self.isPaused = gamePaused
        obstacleSpawnTimer?.isValid ?? false ? obstacleSpawnTimer?.invalidate() : startObstacleSpawnTimer()
        
        // Mostra o nascondi il menu di pausa
        pauseMenu?.isHidden = !gamePaused
    }
    
    func setupPause(){
        let pauseNode = SKSpriteNode(imageNamed: "pause")
        pauseNode.setScale(0.5)
        pauseNode.zPosition = 50.0
        pauseNode.name = "pause"
        pauseNode.position = CGPoint(x: frame.maxX - pauseNode.frame.width * 1.5,
                                     y: frame.midY + pauseNode.frame.height * 3.5)
        self.addChild(pauseNode)
    }
    
    func playBackgroundMusic() {
        if let musicURL = Bundle.main.url(forResource: "backgroundMusic", withExtension: "mp3") {
            backgrounMusic = SKAudioNode(url: musicURL)
            addChild(backgrounMusic!)
        }
    }
    
    func setupScore(){
        scoreLabel.text = "\(numScore)"
        scoreLabel.fontSize = 60.0
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.verticalAlignmentMode = .top
        scoreLabel.zPosition = 30.0
        scoreLabel.position = CGPoint (x: self.frame.midX,
                                       y: self.frame.midY + self.frame.midY/2.0)
        addChild(scoreLabel)
    }
    func addPoints(){
        numScore += 1
        scoreLabel.text = "\(numScore)"
    }
}

