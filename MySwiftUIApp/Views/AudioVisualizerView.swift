import SwiftUI

struct AudioVisualizerView: View {
    let audioLevel: Float
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 4) {
                ForEach(0..<20, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.blue, .cyan, .green, .yellow, .orange, .red]),
                            startPoint: .bottom,
                            endPoint: .top
                        ))
                        .frame(width: 6, height: barHeight(for: index))
                        .animation(.easeInOut(duration: 0.1), value: audioLevel)
                }
            }
            .frame(height: 60)
            
            VStack(spacing: 8) {
                Text("音声レベル")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.green, .yellow, .red]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: geometry.size.width * CGFloat(audioLevel), height: 8)
                            .animation(.easeInOut(duration: 0.1), value: audioLevel)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(.horizontal)
    }
    
    private func barHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 4
        let maxHeight: CGFloat = 60
        
        let normalizedIndex = Float(index) / 19.0
        let levelMultiplier = max(0, audioLevel - abs(normalizedIndex - 0.5) * 2)
        
        return baseHeight + (maxHeight - baseHeight) * CGFloat(levelMultiplier)
    }
}

#Preview {
    VStack {
        AudioVisualizerView(audioLevel: 0.3)
        AudioVisualizerView(audioLevel: 0.7)
        AudioVisualizerView(audioLevel: 1.0)
    }
    .padding()
}
