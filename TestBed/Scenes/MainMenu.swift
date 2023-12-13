//
//  MainMenu.swift
//  TestBed
//
//  Created by Fabio Falco on 10/12/23.
//

import SpriteKit
import SwiftUI



var containerNode:SKSpriteNode!


var highscoreLabel = SKLabelNode(fontNamed:"Chalkduster")

class MainMenu: SKScene{
    @AppStorage("highscore") var highscore:Int = 0
    
    //MARK: - System
    override func didMove(to view: SKView) {
        createBG()
        createGround()
        setupNodes()
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else {return}
        let node = atPoint(touch.location(in: self))
        
        if node.name == "play"{
            let scene = GameScene(size:size)
            scene.scaleMode = scaleMode
            view!.presentScene(scene,transition: .doorsOpenVertical(withDuration: 0.8))
        }else if node.name == "highscore"{
            setupPanel()
        }else if node.name == "setting"{
            setupSetting()
        }else if node.name == "container"{
            containerNode.removeFromParent()
        }else if node.name == "music"{
            
        }else if node.name == "effect"{
        
        }
        
    }
}

//MARK: - Configurations
extension MainMenu{
    func createBG(){
        for i in 0...2{
            let bg = SKSpriteNode(imageNamed: "background")
            bg.name = "BG"
            bg.anchorPoint = .zero
            bg.position = CGPoint(x: CGFloat(i) * bg.frame.width, y: 0.0)
            bg.zPosition = -1.0
            addChild(bg)
        }
    }
    
    func createGround(){
        for i in 0...2{
            let ground = SKSpriteNode(imageNamed: "ground")
            ground.name = "Ground"
            ground.anchorPoint = .zero
            ground.zPosition = 1.0
            ground.position = CGPoint(x: CGFloat(i)*ground.frame.width,
                                      y: 150.0)
            //ground physics
            ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
            ground.physicsBody!.isDynamic = false
            ground.physicsBody!.affectedByGravity = false
           // ground.physicsBody!.categoryBitMask = PhysicsCategory.Ground
            addChild(ground)
        }
    }
    
    func setupNodes(){
        let play = SKSpriteNode(imageNamed: "play")
        play.name = "play"
        play.setScale(0.85)
        play.zPosition = 10.0
        play.position = CGPoint(x: size.width/2.0, y: size.height/2.0 + play.size.height + 50.0)
        addChild(play)
        
        let highscore = SKSpriteNode(imageNamed: "highscore")
        highscore.name = "highscore"
        highscore.setScale(0.85)
        highscore.zPosition = 10.0
        highscore.position = CGPoint(x: size.width/2.0, y: size.height/2.0)
        addChild(highscore)
        
        let setting = SKSpriteNode(imageNamed: "setting")
        setting.name = "setting"
        setting.setScale(0.85)
        setting.zPosition = 10.0
        setting.position = CGPoint(x: size.width/2.0, y: size.height/2.0 - setting.size.height - 50.0)
        addChild(setting)
    }
    func setupPanel(){
        setupContainer()
        
        let panel = SKSpriteNode(imageNamed: "panel")
        panel.setScale(1.5)
        panel.position = .zero
        panel.zPosition = 20.0
        containerNode.addChild(panel)
        
        //highscore
        highscoreLabel.text = "High Score: \(highscore)"
        highscoreLabel.fontSize = 60.0
        highscoreLabel.horizontalAlignmentMode = .center
        highscoreLabel.verticalAlignmentMode = .center
        highscoreLabel.zPosition = 50.0
        highscoreLabel.position = CGPoint (x: panel.frame.midX,
                                           y: panel.frame.midY)
        panel.addChild(highscoreLabel)
    }
    
   func setupSetting(){
       setupContainer()
       
       let panel = SKSpriteNode(imageNamed: "panel")
       panel.setScale(1.5)
       panel.position = .zero
       panel.zPosition = 20.0
       containerNode.addChild(panel)
       
       let resume = SKSpriteNode(imageNamed: "resume")
       resume.name = "resume"
       resume.zPosition = 70.0
       resume.setScale(0.7)
       resume.position = CGPoint(x: -panel.frame.width/2.0 + resume.frame.width * 2.5, y: 0.0)
       panel.addChild(resume)
       
       let quit = SKSpriteNode(imageNamed: "back")
       quit.name = "home"
       quit.zPosition = 70.0
       quit.setScale(0.7)
       quit.position = CGPoint(x: panel.frame.width/2.0 - quit.frame.width * 2.5, y: 0.0)
       panel.addChild(quit)
  
   }
    func setupContainer(){
        containerNode = SKSpriteNode()
        containerNode.name = "container"
        containerNode.zPosition = 15.0
        containerNode.color = .clear
        containerNode.size = size
        containerNode.position = CGPoint(x: size.width/2.0, y: size.height/2.0)
        addChild(containerNode)
    }
}
