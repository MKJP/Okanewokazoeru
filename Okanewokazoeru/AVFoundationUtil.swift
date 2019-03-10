//
//  AVSpeech+AVSound.swift
//  Okanewokazoeru
//
//  Created by Masato Kikkawa on 2019/03/06.
//  Copyright © 2019 Office Kikkawa. All rights reserved.
//

import Foundation
import AVFoundation

class AVSpeech {
    
    static func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        //utterance.rate = AVSpeechUtteranceMaximumSpeechRate
        //utterance.pitchMultiplier = 0.9
        let synth = AVSpeechSynthesizer()
        synth.speak(utterance)
    }

}

class AVSound {
    
    var soundEffect: AVAudioPlayer? = nil
    
    func soundEffectPlay(name:String, loop:Int) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else {
            print("error")
            return
        }
        
        do {
            //try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            self.soundEffect = try AVAudioPlayer(contentsOf: url)
            guard self.soundEffect != nil else {
                return
            }
            self.soundEffect?.numberOfLoops = loop
            self.soundEffect?.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func soundEffectClear() {
        if(soundEffect != nil){
            soundEffect?.stop()
        }
    }
}
