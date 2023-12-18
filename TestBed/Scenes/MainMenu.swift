//
//  MainMenu.swift
//  TestBed
//
//  Created by Fabio Falco on 10/12/23.
//

import SpriteKit
import UIKit

var containerNode:SKSpriteNode!
var highscoreLabel = SKLabelNode(fontNamed:"ARCADECLASSIC")
var dialogLabel: SKLabelNode!
var dialogBackground: SKSpriteNode!
var titleLabel:SKLabelNode!




class MainMenu: SKScene{
    var audioManager = MusicManager.shared
    
    //MARK: - System
    override func didMove(to view: SKView) {
        self.anchorPoint = .zero
        backgroundColor = UIColor(hex: 0xF4EAE4)
        
        setupBarbara()
        createGround()
        setupNodes()
        
        titleLabel = SKLabelNode(fontNamed: "KarmaticArcade")
        titleLabel.text = "Late Deliverable"
        titleLabel.zPosition = 20.0
        titleLabel.fontSize = 80
        titleLabel.fontColor = UIColor.black
        titleLabel.position = CGPoint(x: frame.midX, y: frame.midY * 1.5)
        addChild(titleLabel)
        
        dialogBackground = SKSpriteNode(color: SKColor.white, size: CGSize(width: 400, height: 150))
        dialogBackground.alpha = 0.7  // Opacità dello sfondo
        dialogBackground.position = CGPoint(x: size.width / 5.7, y: size.height / 1.55)
        addChild(dialogBackground)
        
        // Creare il nodo di testo per il dialogo
        dialogLabel = SKLabelNode(fontNamed: "ARCADECLASSIC")
        dialogLabel.text = ""
        dialogLabel.fontColor = UIColor.black
        dialogLabel.fontSize = 30
        dialogLabel.zPosition = 50.0
        dialogLabel.position = CGPoint(x: dialogBackground.position.x, y: dialogBackground.position.y - 20.0)
        
        dialogLabel.numberOfLines = 0  // word wrapping
        dialogLabel.preferredMaxLayoutWidth = dialogBackground.size.width - 20
        addChild(dialogLabel)
        
        dialogBackground.zPosition = dialogLabel.zPosition - 1
        
        let phrases = [ "Hi welcome to the academy!","Did you forget about the final deliverable?!?!","I tell you only one thing...","RUN!!!","P.S. Tap to jump"]
        showTextWithBackground(phrases: phrases)
    }
    
    override func update(_ currentTime: TimeInterval) {
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else {return}
        let node = atPoint(touch.location(in: self))
        
        if node.name == "play"{
            let scene = GameScene(size:size)
            scene.scaleMode = scaleMode
            view!.presentScene(scene,transition: .push(with: .left, duration: 2.5))
        }else if node.name == "highscore"{
            setupPanel()
        }else if node.name == "setting"{
            setupSetting()
        }else if node.name == "container"{
            containerNode.removeFromParent()
        }else if node.name == "music"{
            let node = node as! SKSpriteNode
            audioManager.setMuteMusic()
            node.texture = SKTexture(imageNamed: audioManager.checkMuteMusic() ? "musicOn" : "musicOff")
        }else if node.name == "effect"{
            let node = node as! SKSpriteNode
            audioManager.toggleMute()
            node.texture = SKTexture(imageNamed: audioManager.checkMute() ? "effectOff" : "effectOn")
        }
        
    }
}

//MARK: - Configurations
extension MainMenu{
    // Funzione per visualizzare un elenco di frasi con uno sfondo comune
    func showTextWithBackground(phrases: [String]) {
        // Verifica che ci siano frasi
        guard !phrases.isEmpty else {
            return
        }
        // Funzione ricorsiva per visualizzare le frasi una dopo l'altra
        func displayNextPhrase(index: Int) {
            guard index < phrases.count else {
                return  // Termina la ricorsione quando tutte le frasi sono visualizzate
            }

            let currentPhrase = phrases[index]

            typingEffect(currentPhrase) {
                // Aggiungi un ritardo tra le frasi
                let waitAction = SKAction.wait(forDuration: 1.5)

                // Eseguire l'azione di attesa
                self.run(waitAction, completion: {
                    // Chiamare ricorsivamente per passare alla prossima frase
                    displayNextPhrase(index: index + 1)
                })
            }
        }

        // Avvia la visualizzazione delle frasi
        displayNextPhrase(index: 0)
    }

    // Funzione per simulare l'effetto di scrittura
    func typingEffect(_ text: String, completion: @escaping () -> Void) {
        dialogLabel.text = ""  // Pulisci il testo attuale

        // Itera attraverso ogni carattere nel testo
        for (index, character) in text.enumerated() {
            let waitDuration = TimeInterval(index) * 0.09  // Ritardo tra i caratteri

            // Crea un'azione di attesa per regolare il ritardo
            let waitAction = SKAction.wait(forDuration: waitDuration)

            // Crea un'azione per aggiungere il carattere corrente al testo
            let typeAction = SKAction.run {
                dialogLabel.text?.append(character)
            }

            // Eseguire la sequenza di azioni per ogni carattere
            let typeSequence = SKAction.sequence([waitAction, typeAction])

            // Eseguire la sequenza di azioni sul nodo di testo
            dialogLabel.run(typeSequence)
        }

        // Chiamare la closure di completamento alla fine dell'effetto di scrittura
        let totalDuration = TimeInterval(text.count) * 0.1
        let completionAction = SKAction.wait(forDuration: totalDuration)
        dialogLabel.run(completionAction, completion: completion)
    }
    
    func setupBarbara(){
        let barbara = SKSpriteNode(imageNamed: "Barbara1")
        
        var barbaraTextures:[SKTexture] = []
        for i in 1...8{
            barbaraTextures.append(SKTexture(imageNamed: "Barbara\(i)"))
        }
        barbara.run(.repeatForever(.animate(with: barbaraTextures, timePerFrame: 0.1)))
        
        barbara.name = "barbara"
        barbara.setScale(3.0)
        barbara.zPosition = 3.0
        barbara.position = CGPoint(x: frame.midY/2.0 , y: frame.midY - 18.0)
        
        let desk = SKSpriteNode(imageNamed: "desk")
        desk.name = "desk"
        desk.zPosition = 3.5
        desk.setScale(0.2)
        desk.position = CGPoint(x: barbara.position.x,
                                y: barbara.position.y )
        
        
        self.addChild(barbara)
        self.addChild(desk)
    }
    
    func createGround(){
        for i in 0...3{
            let floor = SKSpriteNode(imageNamed: "floor")
            floor.name = "floor"
            //floor.size = CGSize(width: (self.scene?.size.width)!, height: 250)
            floor.anchorPoint = .zero
            floor.zPosition = 4.0
            floor.position = CGPoint(x: CGFloat(i) * floor.size.width,
                                     y: floor.size.height / 1.5)
            
            self.addChild(floor)
        }
    }
    
    func setupNodes(){
        let play = SKSpriteNode(imageNamed: "play")
        play.name = "play"
        play.setScale(0.5)
        play.zPosition = 10.0
        play.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(play)
        
        let highscore = SKSpriteNode(imageNamed: "highscore")
        highscore.name = "highscore"
        highscore.setScale(0.2)
        highscore.zPosition = 10.0
        highscore.position = CGPoint(x: frame.minX + 100.0,
                                     y: frame.minY + highscore.frame.height * 1.35)
        addChild(highscore)
        
        let setting = SKSpriteNode(imageNamed: "setting")
        setting.name = "setting"
        setting.setScale(0.2)
        setting.zPosition = 10.0
        setting.position = CGPoint(x: frame.maxX - 100.0,
                                   y: frame.minY + setting.frame.height * 1.35 )
        addChild(setting)
    }
    func setupPanel(){
        setupContainer()
        
        let panel = SKSpriteNode(color: SKColor.white, size: CGSize(width: 700, height: 200))
        panel.setScale(1.5)
        panel.position = .zero
        panel.zPosition = 20.0
        containerNode.addChild(panel)
        
        //highscore
        highscoreLabel.text = "High Score: \(HighScoreData.shared.highscore)"
        highscoreLabel.fontSize = 60.0
        highscoreLabel.fontColor = UIColor.black
        highscoreLabel.horizontalAlignmentMode = .center
        highscoreLabel.verticalAlignmentMode = .center
        highscoreLabel.zPosition = 50.0
        highscoreLabel.position = CGPoint (x: panel.frame.midX,
                                           y: panel.frame.midY)
        panel.addChild(highscoreLabel)
    }
    
   func setupSetting(){
       
       setupContainer()
       
       let panel = SKSpriteNode(color: SKColor.white, size: CGSize(width: 700, height: 350))
       panel.setScale(1.5)
       panel.position = .zero
       panel.zPosition = 20.0
       containerNode.addChild(panel)
       
       let effect = audioManager.checkMute() ? "effectOff" : "effectOn"
       let resume = SKSpriteNode(imageNamed: effect)
       resume.name = "effect"
       resume.zPosition = 70.0
       resume.setScale(0.25)
       resume.position = CGPoint(x: -panel.frame.width/2.0 + 350.0, y: 0.0)
       panel.addChild(resume)
       
       let music = audioManager.checkMuteMusic() ? "musicOn" : "musicOff"
       let quit = SKSpriteNode(imageNamed: music)
       quit.name = "music"
       quit.zPosition = 70.0
       quit.setScale(0.25)
       quit.position = CGPoint(x: panel.frame.width/2.0 - 350.0, y: 0.0)
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

extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((hex & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(hex & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
}

