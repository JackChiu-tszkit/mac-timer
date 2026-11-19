import Foundation

/// Generates short notification tones in memory so the app needs no network
/// and no loose audio files. Peaks stay well below full scale.
enum ToneLibrary {
    static let sampleRate = 44_100

    static func createWav(id: AlertSoundId, volume: Double) -> Data {
        let gain = min(max(volume, 0), 1)
        let samples: [Double]
        switch id {
        case .chime:
            samples = chime()
        case .soft:
            samples = tone(frequency: 494, seconds: 1.25, peak: 0.40, attackSeconds: 0.09, decayPower: 0.8)
        case .bell:
            samples = bell()
        }
        var faded = samples
        fadeOut(&faded)
        return encode(faded, gain: gain)
    }

    private static func bell() -> [Double] {
        let fundamental = tone(frequency: 880, seconds: 1.15, peak: 0.38, attackSeconds: 0.004, decayPower: 1.55)
        let harmonic = tone(frequency: 1760, seconds: 0.85, peak: 0.10, attackSeconds: 0.002, decayPower: 2.1)
        return mix(fundamental, harmonic)
    }

    private static func chime() -> [Double] {
        let notes = [523.25, 659.25, 783.99]
        var parts: [Double] = []
        parts.reserveCapacity(sampleRate * 2)
        for frequency in notes {
            parts.append(contentsOf: tone(frequency: frequency, seconds: 0.38, peak: 0.36, attackSeconds: 0.006, decayPower: 1.25))
            parts.append(contentsOf: Array(repeating: 0, count: Int(Double(sampleRate) * 0.045)))
        }
        return parts
    }

    private static func tone(frequency: Double, seconds: Double, peak: Double, attackSeconds: Double, decayPower: Double) -> [Double] {
        let count = max(1, Int(Double(sampleRate) * seconds))
        let attack = max(1, Int(Double(sampleRate) * attackSeconds))
        var data = Array(repeating: 0.0, count: count)
        for index in 0..<count {
            let attackEnvelope = min(1.0, Double(index) / Double(attack))
            let decay = pow(1.0 - (Double(index) / Double(count)), decayPower)
            let wave = sin(2 * Double.pi * frequency * (Double(index) / Double(sampleRate)))
            data[index] = wave * peak * attackEnvelope * decay
        }
        return data
    }

    private static func mix(_ first: [Double], _ second: [Double]) -> [Double] {
        let count = max(first.count, second.count)
        var mixed = Array(repeating: 0.0, count: count)
        for index in 0..<count {
            let a = index < first.count ? first[index] : 0
            let b = index < second.count ? second[index] : 0
            mixed[index] = a + b
        }
        return mixed
    }

    private static func fadeOut(_ data: inout [Double]) {
        let fade = min(data.count, sampleRate / 100)
        guard fade > 0 else { return }
        for index in 0..<fade {
            let gain = 1 - (Double(index) / Double(fade))
            data[data.count - fade + index] *= gain
        }
    }

    private static func encode(_ samples: [Double], gain: Double) -> Data {
        var data = Data()
        let dataSize = samples.count * 2
        data.append(contentsOf: [UInt8]("RIFF".utf8))
        data.appendLE(UInt32(36 + dataSize))
        data.append(contentsOf: [UInt8]("WAVE".utf8))
        data.append(contentsOf: [UInt8]("fmt ".utf8))
        data.appendLE(UInt32(16))
        data.appendLE(UInt16(1))
        data.appendLE(UInt16(1))
        data.appendLE(UInt32(sampleRate))
        data.appendLE(UInt32(sampleRate * 2))
        data.appendLE(UInt16(2))
        data.appendLE(UInt16(16))
        data.append(contentsOf: [UInt8]("data".utf8))
        data.appendLE(UInt32(dataSize))

        for sample in samples {
            let value = min(max(sample * gain, -1), 1)
            let scaled = Int(round(value * Double(Int16.max)))
            data.appendLE(Int16(scaled))
        }
        return data
    }
}

private extension Data {
    mutating func appendLE<T: FixedWidthInteger>(_ value: T) {
        var little = value.littleEndian
        Swift.withUnsafeBytes(of: &little) { bytes in
            append(contentsOf: bytes)
        }
    }
}
