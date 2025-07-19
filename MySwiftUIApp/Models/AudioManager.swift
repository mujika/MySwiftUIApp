import Foundation
import AVFoundation
import SwiftUI

@MainActor
class AudioManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var audioLevel: Float = 0.0
    @Published var recordingDuration: TimeInterval = 0
    @Published var recordings: [Recording] = []
    @Published var hasPermission = false
    
    private var audioRecorder: AVAudioRecorder?
    private var audioEngine = AVAudioEngine()
    private var inputNode: AVAudioInputNode?
    private var recordingTimer: Timer?
    private var levelTimer: Timer?
    
    override init() {
        super.init()
        setupAudioSession()
        loadRecordings()
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
            try session.setActive(true)
        } catch {
            print("オーディオセッションの設定に失敗: \(error)")
        }
    }
    
    func requestPermission() async {
        let permission = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        await MainActor.run {
            self.hasPermission = permission
        }
    }
    
    func startRecording() {
        guard hasPermission else { return }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setActive(true)
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            setupAudioEngine()
            
            isRecording = true
            recordingDuration = 0
            
            startTimers()
            
        } catch {
            print("録音開始に失敗: \(error)")
        }
    }
    
    private func setupAudioEngine() {
        do {
            inputNode = audioEngine.inputNode
            let outputNode = audioEngine.outputNode
            let format = inputNode?.outputFormat(forBus: 0)
            
            inputNode?.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                DispatchQueue.main.async {
                    self.processAudioBuffer(buffer)
                }
            }
            
            if let inputNode = inputNode, let format = format {
                audioEngine.connect(inputNode, to: outputNode, format: format)
            }
            
            try audioEngine.start()
            isPlaying = true
            
        } catch {
            print("オーディオエンジンの設定に失敗: \(error)")
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let channelDataArray = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
        
        let rms = sqrt(channelDataArray.map { $0 * $0 }.reduce(0, +) / Float(channelDataArray.count))
        let avgPower = 20 * log10(rms)
        let normalizedLevel = max(0, (avgPower + 80) / 80)
        
        audioLevel = normalizedLevel
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        isRecording = false
        isPlaying = false
        audioLevel = 0.0
        
        stopTimers()
        loadRecordings()
        
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("オーディオセッション非アクティブ化に失敗: \(error)")
        }
    }
    
    private func startTimers() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                if let recorder = self.audioRecorder, recorder.isRecording {
                    self.recordingDuration = recorder.currentTime
                }
            }
        }
        
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            Task { @MainActor in
                self.audioRecorder?.updateMeters()
                if let recorder = self.audioRecorder {
                    let power = recorder.averagePower(forChannel: 0)
                    let normalizedLevel = max(0, (power + 80) / 80)
                    self.audioLevel = max(self.audioLevel, normalizedLevel)
                }
            }
        }
    }
    
    private func stopTimers() {
        recordingTimer?.invalidate()
        levelTimer?.invalidate()
        recordingTimer = nil
        levelTimer = nil
    }
    
    private func loadRecordings() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: [.creationDateKey], options: [])
            
            recordings = files
                .filter { $0.pathExtension == "m4a" }
                .compactMap { url in
                    guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                          let creationDate = attributes[.creationDate] as? Date else {
                        return nil
                    }
                    return Recording(url: url, creationDate: creationDate)
                }
                .sorted { $0.creationDate > $1.creationDate }
        } catch {
            print("録音ファイルの読み込みに失敗: \(error)")
        }
    }
    
    func deleteRecording(_ recording: Recording) {
        do {
            try FileManager.default.removeItem(at: recording.url)
            loadRecordings()
        } catch {
            print("録音ファイルの削除に失敗: \(error)")
        }
    }
}

extension AudioManager: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            if flag {
                self.loadRecordings()
            }
        }
    }
}
