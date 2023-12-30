//
//  GameScene.swift
//  TestShitty
//
//  Created by Fabio Falco on 12/12/23.
//

import SpriteKit
import GameplayKit
import AVFoundation

class HighScoreData{
    static let shared = HighScoreData()
    
    private init() {}
    
    //Remember highscore
    var highscore:Int {
        get{
            return UserDefaults.standard.integer(forKey: "highscore")
        }
        set{
            UserDefaults.standard.set(newValue, forKey: "highscore")
        }
    }
}

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
    var obstacleTypes:[String] = ["block-1","block-2","block-3"]
    var paper:SKSpriteNode!
    var obstacle:SKSpriteNode!
    var mac:SKSpriteNode!
    
    //Stats
    var velocity:CGFloat = 7.0//Change this value to modify the movement speed
    var difficulty:TimeInterval = 3.0
    var gameOver:Bool = false
    var onGround:Bool = true
    var started = false
    
    //Pause Element
    var gamePaused = false
    var pauseMenu: SKSpriteNode!
    
    //Score element
    var scoreLabel = SKLabelNode(fontNamed:"ARCADECLASSIC")
    var numScore:Int = 0
    
    //Timer
    var timer: Timer? //Timer to count time for point and seconds
    var timerUpdate: TimeInterval = 1.0  //we can set the time interval(in this case evry 1 second)
    var difficultyTimer:Timer?
    var obstacleSpawnTimer: Timer?
    var paperSpawntimer: Timer?
    var macSpawnTimer: Timer?
    
    
    //Variables to handle the jump
    var vel:CGFloat = 0.0
    var gravity:CGFloat = 0.65
    var playerPosY:CGFloat = 0.0
    
    //Sounds
    var coinSound:AVAudioPlayer?
    var deathSound:AVAudioPlayer?
    var jumpSound:AVAudioPlayer?
    var audioManager = MusicManager.shared
    
    
    override func didMove(to view: SKView) {
        //Setup scene
        self.anchorPoint = .zero
        physicsWorld.contactDelegate = self
        setUpNodes()
        //Set up variables
        difficulty = 2.7
        velocity = 9.0
        numScore = 0
        
        audioManager.playBackgroundMusic()
        
        //Create an intro ti the scene
        let introX = SKAction.moveTo(x: frame.midX/2.0, duration: 2.5)
        player.run(.repeat(introX, count: 1)){
            // Start Timer
            self.startTimer()//timer for the points
            self.startObstacleSpawnTimer()
            self.startPaperSpawnTimer()
            self.updateDifficulty()
            self.spawnMac()
            self.started = true
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if !gameOver && started{
            moveGrounds()
            moveBg()
            
            vel += gravity
            player.position.y -= vel
            if player.position.y < playerPosY{
                player.position.y = playerPosY
                vel = 0.0
                onGround = true
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard let touch = touches.first else {return}
        let node = atPoint(touch.location(in: self))
        
        if node.name == "pause" && started{
            togglePause()
        }else if node.name == "resume"{
            togglePause()
        }else if node.name == "home"{
            if numScore > HighScoreData.shared.highscore{HighScoreData.shared.highscore = numScore}
            let scene = MainMenu(size: size)
            scene.scaleMode = scaleMode
            view!.presentScene(scene,transition: .doorsCloseVertical(withDuration: 0.8))
        }else{
            if !gamePaused && started{
                if onGround && !gameOver{
                    onGround = false
                    vel = -25.0
                    playerJump()
                }
            }
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if vel < -12.5{
            vel = -12.5
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        
        if (bodyA.categoryBitMask == PhysicsCategory.Player && bodyB.categoryBitMask == PhysicsCategory.Ground) ||
            (bodyA.categoryBitMask == PhysicsCategory.Ground && bodyB.categoryBitMask == PhysicsCategory.Player) {
            onGround = true
        }
        
        if (bodyA.categoryBitMask == PhysicsCategory.Player && bodyB.categoryBitMask == PhysicsCategory.Paper){
            paperPoints()
            contact.bodyB.node?.removeFromParent()
            if !audioManager.checkMute(){
                coinSound?.volume = 0.5
                coinSound?.play()
            }
        }else if (bodyA.categoryBitMask == PhysicsCategory.Paper && bodyB.categoryBitMask == PhysicsCategory.Player) {
            paperPoints()
            contact.bodyA.node?.removeFromParent()
            if !audioManager.checkMute(){
                coinSound?.volume = 0.5
                coinSound?.play()
            }
        }
        if (bodyA.categoryBitMask == PhysicsCategory.Player && bodyB.categoryBitMask == PhysicsCategory.Obstacle){
            contact.bodyB.node?.removeFromParent()
            if !gameOver{
                setupGameOver()
            }
        }else if (bodyA.categoryBitMask == PhysicsCategory.Obstacle && bodyB.categoryBitMask == PhysicsCategory.Player) {
            contact.bodyA.node?.removeFromParent()
            if !gameOver{
                setupGameOver()
            }
        }
    }
    
    //reset timer when scen has been dealloccated
    deinit {
        timer?.invalidate()
        difficultyTimer?.invalidate()
        paperSpawntimer?.invalidate()
        obstacleSpawnTimer?.invalidate()
        macSpawnTimer?.invalidate()
    }
}

extension GameScene{
    func setUpNodes(){
        createBg()
        createGround()
        createPlayer()
        setupPause()
        setupScore()
        createPauseMenu()
        playCollectibleSound()
        playJumpSound()
        playDeathSound()
    }
    
    //MARK: - Music
    func playCollectibleSound() {
        if let coinSoundURL = Bundle.main.url(forResource: "collectible", withExtension: "wav") {
            do {
                coinSound = try AVAudioPlayer(contentsOf: coinSoundURL)
                coinSound?.prepareToPlay()
            } catch {
                print("Error loading coin sound: \(error.localizedDescription)")
            }
        }
    }
    
    func playJumpSound() {
        if let jumpURL = Bundle.main.url(forResource: "jump", withExtension: "wav") {
            do {
                jumpSound = try AVAudioPlayer(contentsOf: jumpURL)
                jumpSound?.prepareToPlay()
            } catch {
                print("Error loading coin sound: \(error.localizedDescription)")
            }
        }
    }
    func playDeathSound() {
        if let deathUrl = Bundle.main.url(forResource: "death", withExtension: "wav") {
            do {
                deathSound = try AVAudioPlayer(contentsOf: deathUrl)
                deathSound?.prepareToPlay()
            } catch {
                print("Error loading coin sound: \(error.localizedDescription)")
            }
        }
    }
    //MARK: - Elements and their behaviour
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
    @objc func setupMac(){
        mac = SKSpriteNode(imageNamed: "mac")
        mac.setScale(0.5)
        mac.anchorPoint = CGPoint(x: 0.5, y: 0.5)
       // mac.position = CGPoint(x: frame.maxX, y: frame.midY + CGFloat.random(in: 280...300))
        mac.position = CGPoint(x: frame.maxX,
                               y: frame.midY )
        mac.zPosition = 5.0
        
        let rotate = SKAction.rotate(byAngle: 45, duration: 8)
        mac.run(.repeatForever(rotate))
        
        mac.physicsBody = SKPhysicsBody(rectangleOf: mac.size)
        mac.physicsBody?.affectedByGravity = false
        mac.physicsBody?.categoryBitMask = PhysicsCategory.Obstacle
        mac.physicsBody?.contactTestBitMask = PhysicsCategory.Player
        
        if !gameOver && !gamePaused{
            addChild(mac)
            
            let moveAction = SKAction.moveTo(x: -mac.size.width, duration: 3)
            let removeAction = SKAction.removeFromParent()
            mac.run(SKAction.sequence([moveAction, removeAction]))
        }
    }
    
    func moveGrounds(){
        enumerateChildNodes(withName: "floor") { (node, _) in
            if let floorNode = node as? SKSpriteNode {
                // Sposta gli sfondi lateralmente
                floorNode.position.x -= self.velocity
                
                // Verifica se uno degli sfondi è fuori dalla scena
                if floorNode.position.x < -floorNode.size.width {
                    // Riporta lo sfondo alla posizione iniziale dell'altro sfondo
                    floorNode.position.x += floorNode.size.width * 2.0
                }
            }
        }
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
        
        player.setScale(1.2)
        player.position = CGPoint(x: frame.minX - player.size.width,
                                  y: frame.midY - 200.0)
        player.zPosition = 5.0
        player.physicsBody = SKPhysicsBody(circleOfRadius: self.player.size.width/4.0)
        player.physicsBody!.affectedByGravity = false
        player.physicsBody!.restitution = 0.0
        
        player.physicsBody?.categoryBitMask = PhysicsCategory.Player
        player.physicsBody?.contactTestBitMask = PhysicsCategory.Ground | PhysicsCategory.Obstacle
        
        playerPosY = player.position.y
        
        self.addChild(player)
    }
    
    func playerJump(){
        onGround = false
        //animazione jump
        var jumpPlayer: [SKTexture] = []
        for i in 0...2{
            jumpPlayer.append(SKTexture(imageNamed: "0\(i)_Jump"))
        }
        player.run(.repeat(.animate(with: jumpPlayer, timePerFrame: 0.4), count: 1))
        
        //Play jump sound
        jumpSound?.volume = 0.1
        if !audioManager.checkMute(){
            jumpSound?.play()
        }
    }
    
    @objc func spawnObstacle() {
        guard let randomObstacleType = obstacleTypes.randomElement() else { return }
        
        // Aggiorna la variabile difficulty qui, ad esempio in base a punteggi, tempo, ecc.
        let dynamicDifficulty = difficulty
        
        // Aggiorna il timeInterval del timer con il nuovo valore di difficulty
        difficulty = dynamicDifficulty
        
        obstacle = SKSpriteNode(imageNamed: randomObstacleType)
        obstacle.position = CGPoint(x: size.width + obstacle.size.width * 1.5,
                                    y: floor.size.height + 150.0)
        obstacle.zPosition = 5.0
        obstacle.setScale(0.25)
        
        let sizePhysics = CGSize(width: obstacle.size.width / 2.0, height: obstacle.size.height/1.5)
        obstacle.physicsBody = SKPhysicsBody(rectangleOf: sizePhysics)
        obstacle.physicsBody?.affectedByGravity = false
        obstacle.physicsBody?.isDynamic = true
        obstacle.physicsBody?.allowsRotation = false
        obstacle.physicsBody?.categoryBitMask = PhysicsCategory.Obstacle
        obstacle.physicsBody?.contactTestBitMask = PhysicsCategory.Player
        
        if !gameOver && !gamePaused{
            addChild(obstacle)
            
            let moveAction = SKAction.moveTo(x: -obstacle.size.width, duration: 5)
            let removeAction = SKAction.removeFromParent()
            obstacle.run(SKAction.sequence([moveAction, removeAction]))
        }
        startObstacleSpawnTimer()
    }
    
    
    //MARK: - UI
    func createPauseMenu(){
        //Create a pause menu
        pauseMenu = SKSpriteNode(color: SKColor.white, size: CGSize(width: 700, height: 350))
        pauseMenu.setScale(1.5)
        pauseMenu.zPosition = 60.0
        pauseMenu.position = CGPoint(x: size.width / 2, y: size.height / 2)
        pauseMenu?.isHidden = true
        addChild(pauseMenu!)
        
        let resume = SKSpriteNode(imageNamed: "resume")
        resume.name = "resume"
        resume.zPosition = 70.0
        resume.setScale(0.7)
        resume.position = CGPoint(x: -pauseMenu.frame.width/2.0 + 350.0, y: 0.0)
        pauseMenu.addChild(resume)
        
        let quit = SKSpriteNode(imageNamed: "back")
        quit.name = "home"
        quit.zPosition = 70.0
        quit.setScale(0.61)
        quit.position = CGPoint(x: pauseMenu.frame.width/2.0 - 350.0, y: 0.0)
        pauseMenu.addChild(quit)
    }
    func setupPause(){
   
        
        let pauseNode = SKSpriteNode(imageNamed: "pause")
        pauseNode.setScale(0.25)
        pauseNode.zPosition = 50.0
        pauseNode.position = CGPoint(x: frame.maxX - 150.0,
                                     y: frame.maxY - 400.0)
        self.addChild(pauseNode)
        
        let panel = SKSpriteNode(color: SKColor.white, size: CGSize(width: 150, height: 150))
        panel.alpha = 0.01
        panel.position = CGPoint(x: pauseNode.position.x,
                                 y: pauseNode.position.y)
        panel.name = "pause"
        panel.zPosition = 55.0
        addChild(panel)
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
        
        let scoreBackround = SKSpriteNode(color: SKColor.black, size: CGSize(width: 300,
                                                                             height: 100))
        scoreBackround.alpha = 0.4
        scoreBackround.zPosition = scoreLabel.zPosition - 1.0
        scoreBackround.position = scoreLabel.position
        addChild(scoreBackround)
    }
    //MARK: - Functionality
    //Function that handle the pause
    func togglePause() {
        gamePaused = !gamePaused
        
        //Handle music during pause
        if gamePaused {
            timer?.invalidate()
            audioManager.pauseBackgroundMusic()
        } else {
            startTimer()
            audioManager.resumeBackgroundMusic()
        }
        
        // Metti in pausa o riprendi la scena e i timer
        self.isPaused = gamePaused
        //Old pause for timer
        // obstacleSpawnTimer?.isValid ?? false ? obstacleSpawnTimer?.invalidate() : startObstacleSpawnTimer()
        //paperSpawntimer?.isValid ?? false ? paperSpawntimer?.invalidate() : startPaperSpawnTimer()
        //macSpawnTimer?.isValid ?? false ? macSpawnTimer?.invalidate() : spawnMac()
        
        pauseMenu?.isHidden = !gamePaused
    }
    
    //Used by timer to increase difficulty every 200 points
    @objc func increaseVelocity(){
        if((numScore % 200) == 0) && numScore > 0 {
            if (difficulty > 1.7) && (velocity <= 13){
                difficulty -= 0.4
                velocity += 1.0
            }
        }
    }
    
    //Handle the function to count points
    func paperPoints(){
        if !gameOver {
            numScore += 50
            scoreLabel.text = "\(numScore)"
        }
    }
    @objc func addPoints(){
        if !gameOver {
            numScore += 10
            scoreLabel.text = "\(numScore)"
        }
    }
    //Handle the game over sequence
    func setupGameOver(){
        gameOver = true
        
        
        obstacleSpawnTimer?.isValid ?? false ? obstacleSpawnTimer?.invalidate() : startObstacleSpawnTimer()
        paperSpawntimer?.isValid ?? false ? paperSpawntimer?.invalidate() : startPaperSpawnTimer()
        macSpawnTimer?.isValid ?? false ? macSpawnTimer?.invalidate() : spawnMac()
        
        if !onGround{
            let move = SKAction.moveTo(y: playerPosY, duration: 0.8)
            player.run(move)
        }
        
        audioManager.pauseBackgroundMusic()
        if !audioManager.checkMute(){
            deathSound?.play()
        }
        if numScore > HighScoreData.shared.highscore{HighScoreData.shared.highscore = numScore}
        
        var death: [SKTexture] = []
        for i in 0...8{
            death.append(SKTexture(imageNamed: "0\(i)_Death"))
        }
        
        player.run(.repeat(.animate(with: death, timePerFrame: 0.2), count: 1)){
            self.loadGameOverScene()
        }
        
    }
    //Game over Scene
    func loadGameOverScene(){
        audioManager.pauseBackgroundMusic()
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
        for i in 0...3{
            paperTextures.append(SKTexture(imageNamed: "paper\(i)"))
        }
        paper.run(.repeatForever(.animate(with: paperTextures, timePerFrame: 0.5)))
        
        paper.position = CGPoint(x: frame.midX * 4.0, y: frame.midY * 1.2)
        
        let physicBodySize = CGSize(width: paper.size.width / 2.0, height: paper.size.height / 2.0)
        paper.physicsBody = SKPhysicsBody(rectangleOf: physicBodySize)
        paper.physicsBody?.affectedByGravity = false
        paper.physicsBody?.isDynamic = false
        paper.physicsBody?.categoryBitMask = PhysicsCategory.Paper
        paper.physicsBody?.contactTestBitMask = PhysicsCategory.Player
        
        if !gameOver && !gamePaused{
            self.addChild(paper)
            
            
            let moveAction = SKAction.moveTo(x: -paper.size.width, duration: 6)
            let removeAction = SKAction.removeFromParent()
            paper.run(SKAction.sequence([moveAction, removeAction]))
        }
    }
    //MARK: - Timers
    //Gestiamo gli ostacoli
    func startObstacleSpawnTimer() {
        obstacleSpawnTimer?.invalidate()
        obstacleSpawnTimer = Timer.scheduledTimer(timeInterval: difficulty, target: self,
                                                  selector: #selector(spawnObstacle), userInfo: nil, repeats: true)
    }
    //Timer to make epaper Spawn
    func startPaperSpawnTimer(){
        paperSpawntimer = Timer.scheduledTimer(timeInterval: TimeInterval.random(in: 10...15), target: self,
                                               selector: #selector(setupPaper), userInfo: nil, repeats: true)
    }
    //Regular Timer
    func startTimer(){
        timer = Timer.scheduledTimer(timeInterval: timerUpdate, target: self,
                                     selector: #selector(addPoints), userInfo: nil, repeats: true)
    }
    //Timer to increase difficulty
    func updateDifficulty(){
        difficultyTimer = Timer.scheduledTimer(timeInterval: timerUpdate, target: self,
                                               selector: #selector(increaseVelocity), userInfo: nil, repeats: true)
    }
    func spawnMac(){
        macSpawnTimer = Timer.scheduledTimer(timeInterval: 10, target: self,
                                             selector: #selector(setupMac), userInfo: nil, repeats: true)
    }
}
