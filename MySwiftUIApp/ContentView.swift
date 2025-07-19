import SwiftUI

struct ContentView: View {
    @StateObject private var audioManager = AudioManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text("録音アプリ")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if audioManager.isRecording && audioManager.isPlaying {
                        HStack(spacing: 8) {
                            Image(systemName: "dot.radiowaves.left.and.right")
                                .foregroundColor(.red)
                            Text("リアルタイム出力中")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
                
                Spacer()
                
                RecordingControlsView(audioManager: audioManager)
                
                Spacer()
                
                if !audioManager.recordings.isEmpty {
                    VStack(spacing: 8) {
                        Text("\(audioManager.recordings.count)件の録音")
                            .font(.headline)
                        
                        Button("録音一覧を見る") {
                            selectedTab = 1
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                    .padding(.bottom, 40)
                }
            }
            .tabItem {
                Image(systemName: "mic.circle.fill")
                Text("録音")
            }
            .tag(0)
            
            RecordingListView(audioManager: audioManager)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("一覧")
                }
                .tag(1)
        }
        .task {
            await audioManager.requestPermission()
        }
    }
}

#Preview {
    ContentView()
}
