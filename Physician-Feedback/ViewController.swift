//
//  ViewController.swift
//  Physician-Feedback
//
//  Created by ChangS13 on 7/18/25.
//

import UIKit
import AVFoundation
import Speech

class ViewController: UIViewController {
    var isRecording = false
    var isPaused = true
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder?
    var speechRecognizer: SFSpeechRecognizer?

    var transcriptionText: String?
    
    var visualizerView: BarVisualizerView!
    var visualizerTimer: Timer?
    
    var recordingTimer: Timer?
    var elapsedSeconds = 0
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var microphoneButton: UIImageView!
    @IBOutlet weak var pauseResumeButton: UIImageView!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var timerLabel: UILabel!
    
    @IBOutlet weak var informationView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        informationView.layer.shadowColor = UIColor(red: 239/255, green: 212/255, blue: 113/255, alpha: 1.0).cgColor
        informationView.layer.shadowColor = UIColor.black.cgColor
        informationView.layer.shadowOpacity = 0.5
        informationView.layer.shadowOffset = CGSize(width: 0, height: 3)
        
        recordingSession = AVAudioSession.sharedInstance()
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        requestPermissions()
        
        microphoneButton.isHidden = false
        pauseResumeButton.isHidden = true
        stopButton.isHidden = true
        
        visualizerView = BarVisualizerView(frame: CGRect(x: 20, y: 330, width: view.bounds.width - 40, height: 280))
        visualizerView.backgroundColor = .clear
        visualizerView.reset()
        visualizerView.pause()
        view.addSubview(visualizerView)

        visualizerTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.audioRecorder else { return }
            recorder.updateMeters()
            let power = recorder.averagePower(forChannel: 0)
            self.visualizerView.update(withLevel: power)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toAIOutput",
           let destinationVC = segue.destination as? AIOutputViewController {
            destinationVC.transcribedText = self.transcriptionText
        }
    }

    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { status in
            if status == .authorized {
                self.recordingSession.requestRecordPermission { allowed in
                    if !allowed {
                        print("Mic permission denied")
                    }
                }
            } else {
                print("Speech recognition not authorized")
            }
        }
    }
    
    @IBAction func recordButtonPressed(_ sender: Any) {
        if !isRecording {
            startRecording()
            visualizerView.resume()

            microphoneButton.isHidden = true
            pauseResumeButton.isHidden = false
            stopButton.isHidden = false
            
            isPaused = false
            isRecording = true
            
            statusLabel.text = "Recording in progress"
        }
    }
    
    @IBAction func stopButtonPressed(_ sender: Any) {
        if isRecording {
            stopRecording()
            
            microphoneButton.isHidden = false
            pauseResumeButton.isHidden = true
            stopButton.isHidden = true
            
            isRecording = false
        }
    }
    
    @IBAction func pauseResumeButtonPressed(_ sender: Any) {
        guard let recorder = audioRecorder else { return }

        if isPaused {
            recorder.record()
            visualizerView.resume()
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                self.elapsedSeconds += 1
                let minutes = self.elapsedSeconds / 60
                let seconds = self.elapsedSeconds % 60
                self.timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
            }
            
            pauseResumeButton.image = UIImage(systemName: "pause.circle.fill")
            statusLabel.text = "Recording in progress"
            print("Recording resumed")
        } else {
            recorder.pause()
            visualizerView.pause()
            recordingTimer?.invalidate()
            
            pauseResumeButton.image = UIImage(systemName: "play.circle.fill")
            statusLabel.text = "Paused"
            print("Recording paused")
        }

        isPaused.toggle()
    }
    
    func getAudioURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("recording.m4a")
    }
    
     
    func startRecording() {
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        elapsedSeconds = 0
        timerLabel.text = "00:00"

        recordingTimer?.invalidate()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.elapsedSeconds += 1
            let minutes = self.elapsedSeconds / 60
            let seconds = self.elapsedSeconds % 60
            self.timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
        }

     
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
     
            audioRecorder = try AVAudioRecorder(url: getAudioURL(), settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            
            if let recorder = self.audioRecorder {
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                    self.audioRecorder?.updateMeters()
                    let decibels: Float = recorder.averagePower(forChannel: 0)
                    print("Decibels: \(decibels)")
                }
            }
            
            visualizerView.isHidden = false

            print("Recording started")
        } catch {
            print("Failed to start recording:", error)
        }
    }
 
    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        print("Recording stopped")
        transcribeAudio(url: getAudioURL())
        
        visualizerTimer?.invalidate()
        visualizerTimer = nil
        visualizerView.isHidden = true
        
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
 
    func transcribeAudio(url: URL) {
        let request = SFSpeechURLRecognitionRequest(url: url)
        speechRecognizer?.recognitionTask(with: request) { result, error in
            if let result = result {
                self.transcriptionText = result.bestTranscription.formattedString
                print("Transcription: \(result.bestTranscription.formattedString)")

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if self.view.window != nil {
                        self.performSegue(withIdentifier: "toAIOutput", sender: nil)
                    } else {
                        print("View is not in window hierarchy yet")
                    }
                }

            } else if let error = error {
                print("Transcription error:", error)
            }
        }
    }
}

