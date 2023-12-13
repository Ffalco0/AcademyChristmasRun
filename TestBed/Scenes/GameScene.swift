//
//  GameScene.swift
//  TestShitty
//
//  Created by Fabio Falco on 12/12/23.
//

import SpriteKit
import GameplayKit
import SwiftUI

class GameScene: SKScene, SKPhysicsContactDelegate {
    struct PhysicsCategory{
        static let Player:      UInt32 = 0b1
        static let Obstacle:       UInt32 = 0b10
        static let Ground:      UInt32 = 0b100
        static let Paper:      UInt32 = 0
    }
    
    
    //Elements
    var floor:SKSpriteNode!
    var player:SKSpriteNode!
    var bg:SKSpriteNode!
    var obstacleTypes:[String] = ["block-1","block-2","block-3","obstacle-1","obstacle-2"]
    var paper:SKSpriteNode!
    
    //Stats
    var velocity:CGFloat = 7.0//Change this value to modify yhe movement speed
    var difficulty:TimeInterval = 6.0
    
    
    var startTouch = CGPoint()
    var endTouch = CGPoint()
    var onGround:Bool = true
    
    var obstacleSpawnTimer: Timer?
    var paperSpawntimer: Timer?
    
    //Pause Element
    var gamePaused = false
    var pauseMenu: SKSpriteNode!
    
    //Score element
    var scoreLabel = SKLabelNode(fontNamed:"SanFrancisco")
    var numScore:Int = 0
    //Remember highscore
    @AppStorage("highscore") var highscore:Int = 0
    
    //Music
    var backgrounMusic:SKAudioNode?
    
    //Timer
    var timer: Timer?
    var checkTimePass: TimeInterval = 0.0 //here we check an amount of time passed to increase the difficulty
    var timeToCheck:TimeInterval = 50.0 //We set the amount of time
    var intervalloDiAggiornamento: TimeInterval = 1.0  //we can set the time interval(in this case evry 1 second)
    
    override func didMove(to view: SKView) {
        //Setup scene
        self.anchorPoint = .zero
        backgroundColor = .lightGray
        physicsWorld.contactDelegate = self
        // Start Timer and add points
        startTimer()
        playBackgroundMusic()
        
        
        setUpNodes()
        createGround()
        setupPaper()
        
        startObstacleSpawnTimer()
        startPaperSpawnTimer()
    }
  
    
    
    override func update(_ currentTime: TimeInterval) {
        moveGrounds()
        moveBg()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard let touch = touches.first else {return}
        let node = atPoint(touch.location(in: self))
        
        if node.name == "pause" {
            togglePause()
        }else if node.name == "resume"{
            togglePause()
        }else if node.name == "home"{
            if numScore > highscore{highscore = numScore}
            let scene = MainMenu(size: size)
            scene.scaleMode = scaleMode
            view!.presentScene(scene,transition: .doorsCloseVertical(withDuration: 0.8))
        }else{
            let jumpIntensity =  1500.0 //Change the coefficient for a higher jump
            if !gamePaused{
                if onGround{
                    playerJump(withIntensity: jumpIntensity)
                }
            }
        }
        
    }
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        
        if (bodyA.categoryBitMask == PhysicsCategory.Player && bodyB.categoryBitMask == PhysicsCategory.Ground) ||
            (bodyA.categoryBitMask == PhysicsCategory.Ground && bodyB.categoryBitMask == PhysicsCategory.Player) {
            onGround = true
        }
        if (bodyA.categoryBitMask == PhysicsCategory.Player && bodyB.categoryBitMask == PhysicsCategory.Obstacle) ||
            (bodyA.categoryBitMask == PhysicsCategory.Obstacle && bodyB.categoryBitMask == PhysicsCategory.Player) {
            print("GameOver")
            setupGameOver()
        }
        
        if (bodyA.categoryBitMask == PhysicsCategory.Player && bodyB.categoryBitMask == PhysicsCategory.Paper){
            addPoints()
            contact.bodyB.node?.removeFromParent()
        }else if (bodyA.categoryBitMask == PhysicsCategory.Paper && bodyB.categoryBitMask == PhysicsCategory.Player) {
            addPoints()
            contact.bodyA.node?.removeFromParent()
        }
    }
    
    //reset timer when scen has been dealloccated
    deinit {
        // Assicurati di fermare il timer quando la scena viene deallocata
        timer?.invalidate()
    }
}

extension GameScene{
    func setUpNodes(){
        createBg()
        setupPause()
        createPlayer()
        setupScore()
        createPauseMenu()
    }
    
    func createBg(){
        for i in 0...2{
            bg = SKSpriteNode(imageNamed: "Bg\(i)")
            bg.name = "BG"
            bg.setScale(0.62)
            bg.anchorPoint = .zero
            bg.position = CGPoint(x: CGFloat(i) * bg.size.width, y: frame.midY - bg.frame.height/2.0)
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
        enumerateChildNodes(withName: "BG") { (node, _) in
            if let bgNode = node as? SKSpriteNode {
                // Sposta gli sfondi lateralmente
                bgNode.position.x -= self.velocity
                
                // Verifica se uno degli sfondi è fuori dalla scena
                if bgNode.position.x < -bgNode.size.width {
                    // Riporta lo sfondo alla posizione iniziale dell'altro sfondo
                    bgNode.position.x += bgNode.size.width * 2.0
                }
            }
        }
    }
    
    func createPlayer(){
        player = SKSpriteNode(imageNamed: "00_Run")
        //Run animation
        
        var textures:[SKTexture] = []
        for i in 0...8{
            textures.append(SKTexture(imageNamed: "0\(i)_Run"))
        }
        player.run(.repeatForever(.animate(with: textures, timePerFrame: 0.08)))
        
        player.setScale(8.0)
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
        if(checkTimePass == timeToCheck){
            if (difficulty > 1.0){difficulty -= 0.5}
        }
        obstacleSpawnTimer = Timer.scheduledTimer(timeInterval: difficulty, target: self,
                                                  selector: #selector(spawnObstacle), userInfo: nil, repeats: true)
    }
    
    @objc func spawnObstacle() {
        guard let randomObstacleType = obstacleTypes.randomElement() else { return }
        
        let obstacle = SKSpriteNode(imageNamed: randomObstacleType)
        obstacle.position = CGPoint(x: size.width + obstacle.size.width * CGFloat.random(in: 2.5...3.5),
                                    y: size.height / 2)
        obstacle.zPosition = 5.0
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
            timer?.invalidate()
        } else {
            startTimer()
            backgrounMusic?.run(SKAction.play())
        }
        
        // Metti in pausa o riprendi la scena e il timer degli ostacoli
        self.isPaused = gamePaused
        obstacleSpawnTimer?.isValid ?? false ? obstacleSpawnTimer?.invalidate() : startObstacleSpawnTimer()
        paperSpawntimer?.isValid ?? false ? paperSpawntimer?.invalidate() : startPaperSpawnTimer()
        
        // Mostra o nascondi il menu di pausa
        pauseMenu?.isHidden = !gamePaused
    }
    func createPauseMenu(){
        //Create a pause menu
        pauseMenu = SKSpriteNode(imageNamed: "panel")
        pauseMenu.zPosition = 60.0
        pauseMenu.position = CGPoint(x: size.width / 2, y: size.height / 2)
        pauseMenu?.isHidden = true
        addChild(pauseMenu!)
        
        let resume = SKSpriteNode(imageNamed: "resume")
        resume.name = "resume"
        resume.zPosition = 70.0
        resume.setScale(0.7)
        resume.position = CGPoint(x: -pauseMenu.frame.width/2.0 + resume.frame.width * 1.5, y: 0.0)
        pauseMenu.addChild(resume)
        
        let quit = SKSpriteNode(imageNamed: "back")
        quit.name = "home"
        quit.zPosition = 70.0
        quit.setScale(0.7)
        quit.position = CGPoint(x: pauseMenu.frame.width/2.0 - quit.frame.width * 1.5, y: 0.0)
        pauseMenu.addChild(quit)
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
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.zPosition = 30.0
        scoreLabel.position = CGPoint (x: self.frame.midX,
                                       y: self.frame.midY + self.frame.midY/2.0)
        addChild(scoreLabel)
    }
    @objc func addPoints(){
        numScore += 10
        scoreLabel.text = "\(numScore)"
    }
    
    func setupGameOver(){
        if numScore > highscore{highscore = numScore}
        let scene = GameOver(size: size)
        scene.scaleMode = scaleMode
        view!.presentScene(scene,transition: .doorsCloseVertical(withDuration: 0.8))
        
    }
    
    @objc func setupPaper(){
        paper = SKSpriteNode(imageNamed: "paper0")
        paper.name = "paper"
        paper.setScale(1.1)
        paper.zPosition = 5.0
        var paperTextures:[SKTexture] = []
        for i in 0...2{
            paperTextures.append(SKTexture(imageNamed: "paper\(i)"))
        }
        paper.run(.repeatForever(.animate(with: paperTextures, timePerFrame: 0.4)))
        paper.position = CGPoint(x: frame.midX * 4.0, y: frame.midY)
        
        let physicBodySize = CGSize(width: player.size.width / 2.0, height: player.size.height / 2.0)
        paper.physicsBody = SKPhysicsBody(rectangleOf: physicBodySize)
        paper.physicsBody?.affectedByGravity = false
        paper.physicsBody?.isDynamic = false
        paper.physicsBody?.categoryBitMask = PhysicsCategory.Paper
        paper.physicsBody?.contactTestBitMask = PhysicsCategory.Player
        
        self.addChild(paper)
        
        let moveAction = SKAction.moveTo(x: -paper.size.width, duration: 3)
        let removeAction = SKAction.removeFromParent()
        paper.run(SKAction.sequence([moveAction, removeAction]))

    }
    func startPaperSpawnTimer(){
        paperSpawntimer = Timer.scheduledTimer(timeInterval: TimeInterval.random(in: 2...6), target: self,
                                                  selector: #selector(setupPaper), userInfo: nil, repeats: true)
    }
    func startTimer(){
        timer = Timer.scheduledTimer(timeInterval: intervalloDiAggiornamento, target: self,
                                     selector: #selector(addPoints), userInfo: nil, repeats: true)
    }
    
  
}
