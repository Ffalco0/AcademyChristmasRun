//
//  GameOver.swift
//  TestBed
//
//  Created by Fabio Falco on 10/12/23.
//

import Foundation
import SpriteKit
import SwiftUI




class GameOver: SKScene{
    
    var gameOverLable = SKLabelNode(fontNamed:"ARCADECLASSIC")
    var gameOverSubLable = SKLabelNode(fontNamed:"ARCADECLASSIC")
    //MARK: - System
    override func didMove(to view: SKView) {
        createBG()
        createGround()
        setupNodes()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
       
        let scene = MainMenu(size: size)
        scene.scaleMode = scaleMode
        view!.presentScene(scene,transition: .doorsCloseVertical(withDuration: 0.8))
        
    }
}

//MARK: - Configurations
extension GameOver{
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
            //ground.physicsBody!.categoryBitMask = PhysicsCategory.Ground
            addChild(ground)
        }
    }
    
    func setupNodes(){
        setupContainer()
        
        let panel = SKSpriteNode()
        panel.position = .zero
        panel.zPosition = 20.0
        containerNode.addChild(panel)
       
        gameOverLable.text = "Game Over"
        gameOverLable.fontSize = 200.0
        gameOverLable.horizontalAlignmentMode = .center
        gameOverLable.verticalAlignmentMode = .center
        gameOverLable.zPosition = 50.0
        gameOverLable.position = CGPoint (x: panel.frame.midX,
                                          y: panel.frame.midY)
        panel.addChild(gameOverLable)
        
        gameOverSubLable.text = "Tap anywhere to continue"
        gameOverSubLable.fontSize = 50.0
        gameOverSubLable.horizontalAlignmentMode = .center
        gameOverSubLable.verticalAlignmentMode = .center
        gameOverSubLable.zPosition = 50.0
        gameOverSubLable.position = CGPoint(x: panel.frame.midX,
                                            y: panel.frame.midY - gameOverLable.frame.height * 1.5)
        panel.addChild(gameOverSubLable)
        
        breath(node: gameOverLable)

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
    
    func breath(node: SKNode) {
        // Crea un'azione di scala iniziale
        let scalaIniziale = SKAction.scale(to: 1.2, duration: 1.0)
        scalaIniziale.timingMode = .easeInEaseOut
        
        // Crea un'azione di scala finale
        let scalaFinale = SKAction.scale(to: 0.8, duration: 1.0)
        scalaFinale.timingMode = .easeInEaseOut
        
        // Crea un'azione di sequenza che alterna tra le azioni di scala
        let sequenza = SKAction.sequence([scalaIniziale, scalaFinale])
        
        // Ripeti l'azione di sequenza all'infinito
        let animazioneInfinita = SKAction.repeatForever(sequenza)
        
        // Applica l'animazione al nodo
        node.run(animazioneInfinita)
    }
}
