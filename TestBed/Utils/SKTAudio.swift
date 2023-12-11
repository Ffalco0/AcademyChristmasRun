//
//  SKTAudio.swift
//  TestBed
//
//  Created by Fabio Falco on 11/12/23.
//

import AVFoundation

class SKTAudio{
    
    var bgMusic: AVAudioPlayer?
    var soundEffect: AVAudioPlayer?
    
    static func sharedInstance() -> SKTAudio{
        return SKTAudioInstance
    }
    
    func playBGMusic(_ fileNamed: String){
        if !SKTAudio.musicEnabled {return}
        guard let url = Bundle.main.url(forResource: fileNamed, withExtension: nil) else {return}
        
        do{
            bgMusic = try AVAudioPlayer (contentsOf: url)
        }catch let error as NSError{
            print("Error: \(error.localizedDescription)")
            bgMusic = nil
        }
        
        if let bgMusic = bgMusic{
            bgMusic.numberOfLoops = -1
            bgMusic.prepareToPlay()
            bgMusic.play()
        }
    }
    
    func stopMusic(){
        if let bgMusic = bgMusic{
            if bgMusic.isPlaying{ bgMusic.stop()}
        }
    }
    func pauseMusic(){
        if let bgMusic = bgMusic{
            if bgMusic.isPlaying{ bgMusic.pause()}
        }
    }
    func resumeMusic(){
        if let bgMusic = bgMusic{
            if !bgMusic.isPlaying{ bgMusic.play()}
        }
    }
    
    func playSoundEffect(_ fileNamed: String){
        guard let url = Bundle.main.url(forResource: fileNamed, withExtension: "mp3") else {return}
        
        do{
            soundEffect = try AVAudioPlayer(contentsOf: url)
        } catch let error as NSError{
            print("Error: \(error.localizedDescription)")
            soundEffect = nil
        }
        
        if let soundEffect = soundEffect{
            soundEffect.numberOfLoops = 0
            soundEffect.prepareToPlay()
            soundEffect.play()
        }
    }
    
    static let keyMusic = "keyMusic"
    static var musicEnabled:Bool = {
        return !UserDefaults.standard.bool(forKey: keyMusic)
    }(){
        didSet{
            let value = !musicEnabled
            UserDefaults.standard.set(value,forKey: keyMusic)
            
            if value {
                SKTAudio.sharedInstance().stopMusic()
            }
        }
    }
}

private let SKTAudioInstance = SKTAudio()
