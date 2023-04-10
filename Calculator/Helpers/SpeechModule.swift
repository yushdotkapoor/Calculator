//
//  SpeechModule.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 3/25/23.
//

import Foundation
import UIKit
import Speech

class SpeechModule:NSObject {
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    enum Behavior {
        case chooseKeyPhrase
        case authenticate
    }
    
    var behavior: Behavior!
    var controller: PassKeyView!
    
    var cache:String?
    var stop = false
    
    
    /*
     Create variables to pass functions or UIElements here
     */
    
    init(behavior: Behavior, controller: PassKeyView) {
        self.behavior = behavior
        self.controller = controller
    }
    
    func startRecording() {
        print("Speech Recognition Started")
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        stop = false
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { [self] (result, error) in
            
            var isFinal = false
            
            //HANDLE SPEECH RESULT HERE
            if result != nil {
                let spokenContent = result?.bestTranscription.formattedString.lowercased()
                let str:[String.SubSequence] = "\(cache ?? "") \(spokenContent ?? "")".split(separator: " ")
                
                let new = str[(str.lastIndex(of: "clear") ?? str.startIndex)..<str.endIndex]
                
                controller.rippleView.ripple()
                controller.bottomLabel.text = new.joined(separator: " ")
                if behavior == .chooseKeyPhrase {
                    if new.count >= 10 {
                        impact(style: .soft)
                        controller.isOn = false
                    }
                } else if new.joined(separator: " ").contains(controller.targetText) {
                    impact(style: .success)
                    controller.isOn = false
                }
                
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                deinitializeObjects()
                cache = "\(cache ?? "") \(result?.bestTranscription.formattedString.lowercased() ?? "")"
                print("Speech Recognition Stopped")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: { [self] in
                    if !self.isActive() && !stop {
                        print("Speech Recognition Activated again")
                        startRecording()
                    }
                })
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 1)
        
        inputNode.installTap(onBus: 1, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
    }
    
    
    func stopRecording() {
        pause()
        print("audioEngine stopped")
    }
    
    func pause() {
        print("talk pause")
        cache = ""
        deinitializeObjects()
    }
    
    func deinitializeObjects() {
        audioEngine.inputNode.removeTap(onBus: 1)
        recognitionRequest?.endAudio()
        self.recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        audioEngine.stop()
    }
    
    func play() {
        print("talk play")
        startRecording()
    }
    
    func isActive() -> Bool {
        return audioEngine.isRunning
    }
    
    
    deinit {
        stopRecording()
    }
    
    
    
}
