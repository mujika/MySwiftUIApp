import SwiftUI

struct RecordingControlsView: View {
    @ObservedObject var audioManager: AudioManager
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 8) {
                Text(audioManager.isRecording ? "録音中" : "待機中")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(audioManager.isRecording ? .red : .secondary)
                
                if audioManager.isRecording {
                    Text(formatTime(audioManager.recordingDuration))
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
            
            AudioVisualizerView(audioLevel: audioManager.audioLevel)
            
            Button(action: {
                if audioManager.isRecording {
                    audioManager.stopRecording()
                } else {
                    audioManager.startRecording()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(audioManager.isRecording ? Color.red : Color.blue)
                        .frame(width: 120, height: 120)
                        .shadow(color: audioManager.isRecording ? .red.opacity(0.3) : .blue.opacity(0.3), radius: 20)
                    
                    if audioManager.isRecording {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                            .frame(width: 40, height: 40)
                    } else {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                }
            }
            .scaleEffect(audioManager.isRecording ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: audioManager.isRecording)
            .disabled(!audioManager.hasPermission)
            
            if !audioManager.hasPermission {
                Text("マイクへのアクセス許可が必要です")
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    RecordingControlsView(audioManager: AudioManager())
}
