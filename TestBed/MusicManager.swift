//
//  MusicManager.swift
//  TestShitty
//
//  Created by Fabio Falco on 14/12/23.
//

import SpriteKit
import AVFoundation
import SwiftUI

class MusicManager {
    static let shared = MusicManager()

    private var backgroundMusicPlayer: AVAudioPlayer?
    //Sounds
    private var coinSound:AVAudioPlayer?
    private var deathSound:AVAudioPlayer?
    private var jumpSound:AVAudioPlayer?
    
    private var isMusicPlaying: Bool {
        get{
            return UserDefaults.standard.bool(forKey: "isMusicPlaying")
        }
        set{
            UserDefaults.standard.set(newValue, forKey: "isMusicPlaying")
        }
    }//It will remember the user preferences!
    private var isMutedSounds: Bool {
        get{
            return UserDefaults.standard.bool(forKey: "isMutedSounds")
        }
        set{
            UserDefaults.standard.set(newValue, forKey: "isMutedSounds")
        }
    }//It will remember the user preferences!
    
    private init() {}
    
    func playBackgroundMusic() {
        if isMusicPlaying{
            guard let musicURL = Bundle.main.url(forResource: "Its_Snowtime_MP3", withExtension: "mp3") else {
                return
            }

            do {
                backgroundMusicPlayer = try AVAudioPlayer(contentsOf: musicURL)
                backgroundMusicPlayer?.numberOfLoops = -1
                backgroundMusicPlayer?.volume = 0.5
                backgroundMusicPlayer?.prepareToPlay()
                
                if isMusicPlaying{backgroundMusicPlayer?.play()}
            } catch {
                print("Errore nella riproduzione della musica: \(error.localizedDescription)")
            }
        }
    }
    func checkMuteMusic() -> Bool{
        return isMusicPlaying
    }
    func pauseBackgroundMusic() {
        backgroundMusicPlayer?.pause()
    }

    func resumeBackgroundMusic() {
        backgroundMusicPlayer?.play()
    }
    func setMuteMusic(){
        isMusicPlaying = !isMusicPlaying
    }
    
    //MARK: -Sounds
    
    func checkMute() -> Bool{
        return isMutedSounds
    }
    func toggleMute() {
        isMutedSounds = !isMutedSounds
    }
}


