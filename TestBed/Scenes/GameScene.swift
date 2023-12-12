//
//  GameScene.swift
//  TestBed
//
//  Created by Fabio Falco on 05/12/23.
//

import SpriteKit
import GameplayKit
import SwiftUI


class GameScene: SKScene {
    //MARK: - Properties
    var ground: SKSpriteNode!
    var player: SKSpriteNode!
    var cameraNode = SKCameraNode()
    var obstacles:[SKSpriteNode] = []
    
    var cameraMovePointsPerSeconds: CGFloat = 450.0
    
    var lastUpdateTime: TimeInterval = 0.0
    var dt: TimeInterval = 0.0
    
    var onGround = true
    var velocity:CGFloat = 0.0
    var gravity:CGFloat = 0.6
    var playerPosY:CGFloat = 0.0
    
    var numScore:Int = 0
    var gameOver = false
    
    //UI
    var scoreLabel = SKLabelNode(fontNamed:"Chalkduster")
    var pauseNode: SKSpriteNode!
    var containerNode = SKNode()
    
    //Remember highscore
    @AppStorage("highscore") var highscore:Int = 0
    
    //MUSIC
    var soundJump = SKAction.playSoundFileNamed("jump.wav")
    var soundCollision = SKAction.playSoundFileNamed("collision.wav")
    
    var playbleRect: CGRect {
        let ratio:CGFloat
        switch UIScreen.main.nativeBounds.height{
        case 2688,1792,2436:
            ratio = 2.16
        default:
            ratio = 16/9
        }
        let playbleHeight = size.width / ratio
        let playbleMargin = (size.height - playbleHeight) / 2.0
        
        return CGRect (x: 0.0, y: playbleMargin, width: size.width, height: playbleHeight)
    }
    
    var cameraRect: CGRect{
        let width = playbleRect.width
        let height = playbleRect.height
        let x = cameraNode.position.x - size.width/2.0 + (size.width - width)/2.0
        let y = cameraNode.position.y - size.height/2.0 + (size.height - height)/2.0
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    //MARK: - Systems
    override func didMove(to view: SKView) {
        setupNodes()
        
        SKTAudio.sharedInstance().playBGMusic("backgroundMusic")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard let touch = touches.first else {return}
        let node = atPoint(touch.location(in: self))
        
        if node.name == "pause"{
            if isPaused{return}
            createPAnel()
            lastUpdateTime = 0.0
            dt = 0.0
            isPaused = true
        } else if node.name == "resume"{
            containerNode.removeFromParent()
            isPaused = false
        }else if node.name == "home"{
            if numScore > highscore{highscore = numScore}
            let scene = MainMenu(size: size)
            scene.scaleMode = scaleMode
            view!.presentScene(scene,transition: .doorsCloseVertical(withDuration: 0.8))
        }else{
            if !isPaused{
                if onGround{
                    onGround = false
                    velocity = -25.0
                    numScore += 1
                    scoreLabel.text = "\(numScore)"
                    //animazione jump
                    var jumpPlayer: [SKTexture] = []
                    for i in 0...2{
                        jumpPlayer.append(SKTexture(imageNamed: "0\(i)_Jump"))
                    }
                    
                    player.run(.repeat(.animate(with: jumpPlayer, timePerFrame: 0.4), count: 1))
                    
                    run(soundJump)
                }
            }
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if velocity < -12.5{
            velocity = -12.5
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime > 0{
            dt = currentTime - lastUpdateTime
        }else{
            dt = 0
        }
        lastUpdateTime = currentTime
        moveCamera()
        movePlayer()
        
        velocity += gravity
        player.position.y -= velocity
        
        if player.position.y < playerPosY{
            player.position.y = playerPosY
            velocity = 0.0
            onGround = true
        }
    }
    
}
//MARK: - Configuratoin
extension GameScene{
    func setupNodes(){
        createBG()
        createGround()
        createCieling()
        createPlayer()
        spawnBlock()
        setupCamera()
        setupScore()
        setupPause()
        setupPhysic()
    }
    
    func setupPhysic(){
        physicsWorld.contactDelegate = self
    }
    
    func createBG(){
        for i in 0...1{
            let bg = SKSpriteNode(imageNamed: "Bg\(i)")
            bg.name = "BG"
            bg.anchorPoint = .zero
            bg.position = CGPoint(x: CGFloat(i) * bg.frame.width, y: 0.0)
            bg.zPosition = -1.0
            addChild(bg)
        }
    }
    func createCieling(){
        for i in 0...1{
            let cieling = SKSpriteNode(imageNamed: "cieling")
            cieling.name = "cieling"
            cieling.anchorPoint = .zero
            cieling.zPosition = 1.0
            cieling.position = CGPoint(x: CGFloat(i)*cieling.frame.width,
                                       y: frame.height - cieling.frame.height * 2.0)
            /*
            cieling.physicsBody = SKPhysicsBody(rectangleOf: cieling.size)
            cieling.physicsBody!.isDynamic = false
            cieling.physicsBody!.affectedByGravity = false
             */
            addChild(cieling)
        }
    }
    func createGround(){
        for i in 0...1{
            ground = SKSpriteNode(imageNamed: "ground")
            ground.name = "Ground"
            ground.anchorPoint = .zero
            ground.zPosition = 1.0
            ground.position = CGPoint(x: CGFloat(i)*ground.frame.width,
                                      y: 0.0)
            //ground physics
            ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
            ground.physicsBody!.isDynamic = false
            ground.physicsBody!.affectedByGravity = false
            ground.physicsBody!.categoryBitMask = PhysicsCategory.Ground
            addChild(ground)
        }
    }
    func createPlayer(){
        player = SKSpriteNode(imageNamed: "00_Run")
        player.name = "Player"
        player.zPosition = 5.0
        player.setScale(3.5)
        player.position = CGPoint(x: frame.width/2.0 - 100.0,
                                  y: ground.frame.height + player.frame.height/2.0)
        
        //Animation player
        var textures:[SKTexture] = []
        for i in 0...8{
            textures.append(SKTexture(imageNamed: "0\(i)_Run"))
        }
        player.run(.repeatForever(.animate(with: textures, timePerFrame: 0.08)))
        
        
        //player physics
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width/4.0)
        player.physicsBody!.affectedByGravity = false
        player.physicsBody!.restitution = 0.0
        
        player.physicsBody!.categoryBitMask = PhysicsCategory.Player
        player.physicsBody!.contactTestBitMask = PhysicsCategory.Block | PhysicsCategory.Obstacle
        
        playerPosY = player.position.y
        
        addChild(player)
    }
    
    func setupCamera(){
        addChild(cameraNode)
        camera = cameraNode
        cameraNode.position = CGPoint(x: frame.midX, y: frame.midY - 150.0)
    }
    func moveCamera(){
        let amountToMove = CGPoint(x: cameraMovePointsPerSeconds * CGFloat(dt),
                                   y: 0.0)
        
        /* cameraNode.position = CGPoint(x: cameraNode.position.x + amountToMove.x,
         y: cameraNode.position.y + amountToMove.y)*/
        
        //Now we will use the override function that we create
        cameraNode.position += amountToMove
        
        //background
        enumerateChildNodes(withName: "BG"){(node,_) in
            let node = node as! SKSpriteNode
            
            if node.position.x + node.frame.width < self.cameraRect.origin.x{
                node.position = CGPoint (x: node.position.x + node.frame.width*2.0, y: node.position.y)
            }
        }
        
        //ground
        enumerateChildNodes(withName: "Ground"){(node,_) in
            let node = node as! SKSpriteNode
            
            if node.position.x + node.frame.width < self.cameraRect.origin.x{
                node.position = CGPoint (x: node.position.x + node.frame.width*2.0, y: node.position.y)
            }
        }
        //cieling
        enumerateChildNodes(withName: "cieling"){(node,_) in
            let node = node as! SKSpriteNode
            
            if node.position.x + node.frame.width < self.cameraRect.origin.x{
                node.position = CGPoint (x: node.position.x + node.frame.width*2.0, y: node.position.y)
            }
        }
    }
    func movePlayer(){
        let amountToMove = cameraMovePointsPerSeconds * CGFloat(dt)
        //let rotate = CGFloat(1).degreeToRadians() * amountToMove/2.5
        //rotation
        //player.zRotation -= rotate
        player.position.x += amountToMove
    }
    
    func setUpObstacle(){
        for i in 1...3{
            let sprite = SKSpriteNode(imageNamed: "block-\(i)")
            sprite.name = "Block"
            sprite.setScale(1.2)
            obstacles.append(sprite)
        }
        for i in 1...2{
            let sprite = SKSpriteNode(imageNamed: "obstacle-\(i)")
            sprite.name = "Obstacle"
            sprite.setScale(0.9)
            obstacles.append(sprite)
        }
        
        let index = Int(arc4random_uniform(UInt32(obstacles.count - 1)))
        let sprite = obstacles[index].copy() as! SKSpriteNode
        sprite.zPosition = 5.0
        sprite.position = CGPoint(x: cameraRect.maxX + sprite.frame.width/2.0,
                                  y: ground.frame.height + sprite.frame.height/2.0)
        //Obstacle physics
        sprite.physicsBody = SKPhysicsBody(rectangleOf: sprite.size)
        sprite.physicsBody!.affectedByGravity = false
        sprite.physicsBody!.isDynamic = false
        
        if sprite.name == "Block"{
            sprite.physicsBody!.categoryBitMask = PhysicsCategory.Block
        }else{
            sprite.physicsBody!.categoryBitMask = PhysicsCategory.Obstacle
        }
        sprite.physicsBody!.contactTestBitMask = PhysicsCategory.Player
        
        addChild(sprite)
        sprite.run(.sequence([
            .wait(forDuration: 10.0),
            .removeFromParent(),
        ]))
    }
    
    func spawnBlock(){
        let random = Double(CGFloat.random(min: 1.5, max: 3.0))
        run(.repeatForever(.sequence([
            .wait(forDuration: random),
            .run { [weak self] in
                self?.setUpObstacle()
            }
        ])))
    }
    func setupScore(){
        scoreLabel.text = "\(numScore)"
        scoreLabel.fontSize = 60.0
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.verticalAlignmentMode = .top
        scoreLabel.zPosition = 50.0
        scoreLabel.position = CGPoint (x: 0.0,
                                       y: 450.0)
        cameraNode.addChild(scoreLabel)
    }
    func setupPause(){
        pauseNode = SKSpriteNode(imageNamed: "pause")
        pauseNode.setScale(0.5)
        pauseNode.zPosition = 50.0
        pauseNode.name = "pause"
        pauseNode.position = CGPoint(x: playbleRect.width/2.0 - pauseNode.frame.width/2.0 - 50.0,
                                     y: playbleRect.height/2.0 - pauseNode.frame.height/2.0 - 150.0)
        cameraNode.addChild(pauseNode)
    }
    func createPAnel(){
        cameraNode.addChild(containerNode)
        
        let panel = SKSpriteNode(imageNamed: "panel")
        panel.position = .zero
        panel.zPosition = 60.0
        containerNode.addChild(panel)
        
        let resume = SKSpriteNode(imageNamed: "resume")
        resume.name = "resume"
        resume.zPosition = 70.0
        resume.setScale(0.7)
        resume.position = CGPoint(x: -panel.frame.width/2.0 + resume.frame.width * 1.5, y: 0.0)
        panel.addChild(resume)
        
        let quit = SKSpriteNode(imageNamed: "back")
        quit.name = "home"
        quit.zPosition = 70.0
        quit.setScale(0.7)
        quit.position = CGPoint(x: panel.frame.width/2.0 - quit.frame.width * 1.5, y: 0.0)
        panel.addChild(quit)
    }
    
    func setupGameOver(){
        if !gameOver {
            gameOver = true
            if numScore > highscore{highscore = numScore}
            let scene = GameOver(size: size)
            scene.scaleMode = scaleMode
            view!.presentScene(scene,transition: .doorsCloseVertical(withDuration: 0.8))
        }
    }
}

//MARK: -SKPhysicsContactDelegate
extension GameScene:SKPhysicsContactDelegate{
    func didBegin(_ contact: SKPhysicsContact) {
        let other = contact.bodyA.categoryBitMask == PhysicsCategory.Player ? contact.bodyB : contact.bodyA
        
        switch other.categoryBitMask{
        case PhysicsCategory.Block:
            run(soundCollision)
            setupGameOver()
        case PhysicsCategory.Obstacle:
            run(soundCollision)
            setupGameOver()
        default: break
        }
    }
}
