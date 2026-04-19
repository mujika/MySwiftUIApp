import Accelerate
import AVFoundation
import Foundation

// MARK: - Protocol

protocol SpectrogramService {
    var frequencyBins: [Float] { get }
    var binCount: Int { get }
    func start() throws
    func stop()
}

// MARK: - Implementation (vDSP FFT)

final class AccelerateSpectrogram: SpectrogramService {
    private var engine: AVAudioEngine?
    private let fftSize: Int
    private let log2n: vDSP_Length

    private var fftSetup: FFTSetup?
    private var window: [Float]

    private(set) var frequencyBins: [Float]
    var binCount: Int { fftSize / 2 }

    init(fftSize: Int = 2048) {
        self.fftSize = fftSize
        self.log2n = vDSP_Length(log2(Double(fftSize)))
        self.window = [Float](repeating: 0, count: fftSize)
        self.frequencyBins = [Float](repeating: 0, count: fftSize / 2)
        vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
    }

    func start() throws {
        fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))

        let engine = AVAudioEngine()
        let input = engine.inputNode
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!

        input.installTap(onBus: 0, bufferSize: AVAudioFrameCount(fftSize), format: format) { [weak self] buffer, _ in
            self?.processFFT(buffer)
        }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .mixWithOthers])
        try session.setActive(true)

        engine.prepare()
        try engine.start()
        self.engine = engine
    }

    func stop() {
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        engine = nil
        if let setup = fftSetup {
            vDSP_destroy_fftsetup(setup)
            fftSetup = nil
        }
        frequencyBins = [Float](repeating: 0, count: binCount)
    }

    // MARK: - FFT Processing

    private func processFFT(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0],
              let fftSetup else { return }

        let frameCount = Int(buffer.frameLength)
        guard frameCount >= fftSize else { return }

        // Apply Hann window
        var windowed = [Float](repeating: 0, count: fftSize)
        vDSP_vmul(channelData, 1, window, 1, &windowed, 1, vDSP_Length(fftSize))

        // Split complex for FFT
        var realPart = [Float](repeating: 0, count: fftSize / 2)
        var imagPart = [Float](repeating: 0, count: fftSize / 2)

        // Deinterleave
        for i in 0..<fftSize / 2 {
            realPart[i] = windowed[2 * i]
            imagPart[i] = windowed[2 * i + 1]
        }

        var splitComplex = DSPSplitComplex(realp: &realPart, imagp: &imagPart)

        // Forward FFT
        vDSP_fft_zip(fftSetup, &splitComplex, 1, log2n, FFTDirection(kFFTDirection_Forward))

        // Magnitude (power spectrum)
        var magnitudes = [Float](repeating: 0, count: fftSize / 2)
        vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(fftSize / 2))

        // Convert to dB and normalize
        var dbMagnitudes = [Float](repeating: 0, count: fftSize / 2)
        var one: Float = 1e-6
        vDSP_vsadd(magnitudes, 1, &one, &dbMagnitudes, 1, vDSP_Length(fftSize / 2))

        var count = Int32(fftSize / 2)
        vvlog10f(&dbMagnitudes, dbMagnitudes, &count)
        var twenty: Float = 20
        vDSP_vsmul(dbMagnitudes, 1, &twenty, &dbMagnitudes, 1, vDSP_Length(fftSize / 2))

        // Normalize to 0..1 range (assuming -80dB to 0dB range)
        var normalized = [Float](repeating: 0, count: fftSize / 2)
        for i in 0..<fftSize / 2 {
            normalized[i] = max(0, min(1, (dbMagnitudes[i] + 80) / 80))
        }

        frequencyBins = normalized
    }
}
