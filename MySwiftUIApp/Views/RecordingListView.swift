import SwiftUI
import AVFoundation

struct RecordingListView: View {
    @ObservedObject var audioManager: AudioManager
    @State private var playingRecording: Recording?
    @State private var audioPlayer: AVAudioPlayer?
    
    var body: some View {
        NavigationView {
            List {
                if audioManager.recordings.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "waveform.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("録音がありません")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Text("録音ボタンを押して最初の録音を作成しましょう")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(audioManager.recordings) { recording in
                        RecordingRowView(
                            recording: recording,
                            isPlaying: playingRecording?.id == recording.id,
                            onPlay: { playRecording(recording) },
                            onStop: { stopPlayback() },
                            onDelete: { audioManager.deleteRecording(recording) }
                        )
                    }
                }
            }
            .navigationTitle("録音一覧")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
            }
        }
    }
    
    private func playRecording(_ recording: Recording) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: recording.url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            playingRecording = recording
        } catch {
            print("再生に失敗: \(error)")
        }
    }
    
    private func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        playingRecording = nil
    }
}

struct RecordingRowView: View {
    let recording: Recording
    let isPlaying: Bool
    let onPlay: () -> Void
    let onStop: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recording.name)
                    .font(.headline)
                
                Text(formatDate(recording.creationDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: isPlaying ? onStop : onPlay) {
                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.title3)
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("削除", role: .destructive) {
                onDelete()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

extension RecordingListView: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playingRecording = nil
        audioPlayer = nil
    }
}

#Preview {
    RecordingListView(audioManager: AudioManager())
}
