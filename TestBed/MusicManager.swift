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
    @AppStorage("isMusicPlaying") var isMusicPlaying:Bool = true//It will remember the user preferences!

    private init() {

        // Inizializzazione, ad esempio, caricamento delle tracce audio
    }
    
    func playBackgroundMusic() {
        if isMusicPlaying{
            guard let musicURL = Bundle.main.url(forResource: "Its_Snowtime_MP3", withExtension: "mp3") else {
                return
            }

            do {
                backgroundMusicPlayer = try AVAudioPlayer(contentsOf: musicURL)
                backgroundMusicPlayer?.numberOfLoops = -1
                backgroundMusicPlayer?.prepareToPlay()
                
                if isMusicPlaying{backgroundMusicPlayer?.play()}
            } catch {
                print("Errore nella riproduzione della musica: \(error.localizedDescription)")
            }
        }
    }

    func pauseBackgroundMusic() {
        isMusicPlaying = false
        backgroundMusicPlayer?.pause()
    }

    func resumeBackgroundMusic() {
        isMusicPlaying = true
        backgroundMusicPlayer?.play()
    }
    func setMuteMusic(){
        isMusicPlaying = !isMusicPlaying
        print(isMusicPlaying)
    }
}

