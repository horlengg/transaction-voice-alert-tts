import SwiftUI
import AVFoundation

struct VoiceOption: Identifiable {
    let id : String
    let name: String
    let gender: String
    let language: String
}

struct LanguageOption: Identifiable {
    let id: String
    let label: String
    let flag: String
}

enum AmountError: LocalizedError {
    case hasDecimal
    case belowMinimum

    var errorDescription: String? {
        switch self {
        case .hasDecimal:   return "KHR amount cannot have decimals."
        case .belowMinimum: return "KHR amount must be at least 100 ៛."
        }
    }
}


struct ContentView : View {
    @State private var amount = "1000"
    @State private var selectedCurrency = "USD"
    @State private var selectedVoice = VoiceOption(id : "piseth",name: "Piseth",  gender: "Male",   language: "Khmer")
    @State private var selectedLanguage = LanguageOption(id: "km-kh", label: "Khmer", flag: "🇰🇭")

    @State private var audioPlayer: AVAudioPlayer?
    @State private var isLoading = false
    @State private var isPlaying = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var generationTime: Double? = nil
    @State private var audioSize: Int? = nil
    @State private var audioData: Data? = nil
    @State private var playbackProgress: Double = 0
    @State private var playbackTimer: Timer? = nil
    @State private var errorMsg : String? = nil

    let currencies = ["USD", "KHR"]
    let voices = [
        VoiceOption(id : "sreymom",name: "Sreymom", gender: "Female", language: "Khmer"),
        VoiceOption(id : "piseth",name: "Piseth",  gender: "Male",   language: "Khmer"),
    ]
    let languages = [
        LanguageOption(id: "km-kh", label: "Khmer",   flag: "🇰🇭"),
        LanguageOption(id: "en-us", label: "English",  flag: "🇺🇸"),
    ]

    var body: some View {
        ZStack {
            Color(hex: "#0D0D0F").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    header
                    inputCard
                    voiceCard
                    generateButton
                    if audioData != nil { playerCard }
                    if generationTime != nil { statsRow }
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
        }
        .alert("Playback Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Header

    var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("OpenAI TTS")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Text-to-speech · Transaction audio")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(hex: "#6B6B7A"))
                }
                Spacer()
                Circle()
                    .fill(Color(hex: "#1A1A2E"))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "waveform")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(hex: "#7C6FF7"))
                    )
            }
            .padding(.top, 60)
            .padding(.bottom, 28)
        }
    }

    var inputCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            label("Transaction")

            // Amount row
            HStack(spacing: 0) {
                Text(currencySymbol)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#7C6FF7"))
                    .frame(width: 36)

                TextField("0.00", text: $amount)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .keyboardType(.decimalPad)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(hex: "#17171F"))
            .cornerRadius(12)


            HStack(spacing: 8) {
                ForEach(currencies, id: \.self) { c in
                    currencyChip(c)
                }
            }

            Divider().background(Color(hex: "#2A2A38")).padding(.vertical, 4)

            label("Language")
            HStack(spacing: 8) {
                ForEach(languages) { lang in
                    languageChip(lang)
                }
                Spacer()
            }
        }
        .padding(20)
        .background(Color(hex: "#12121A"))
        .cornerRadius(20)
        .padding(.bottom, 12)
    }

    // MARK: - Voice Card

    var voiceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            label("Voice")
            HStack(spacing: 10) {
                ForEach(voices) { v in
                    voiceChip(v)
                }
                Spacer()
            }
        }
        .padding(20)
        .background(Color(hex: "#12121A"))
        .cornerRadius(20)
        .padding(.bottom, 12)
    }

    // MARK: - Generate Button

    var generateButton: some View {
        Button(action: generateTrxSpeech) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.85)
                    Text("Generating…")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Generate Audio")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isLoading
                    ? Color(hex: "#3D3A6B")
                    : Color(hex: "#7C6FF7")
            )
            .cornerRadius(14)
        }
        .disabled(isLoading || amount.isEmpty)
        .padding(.bottom, 12)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }

    // MARK: - Player Card

    var playerCard: some View {
        VStack(spacing: 16) {
            // Waveform decoration
            HStack(spacing: 3) {
                ForEach(0..<28, id: \.self) { i in
                    let h = waveBarHeight(index: i)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor(index: i))
                        .frame(width: 3, height: h)
                        .animation(.easeInOut(duration: 0.4).delay(Double(i) * 0.02), value: isPlaying)
                }
            }
            .frame(height: 40)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "#2A2A38"))
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "#7C6FF7"))
                        .frame(width: geo.size.width * playbackProgress, height: 3)
                }
            }
            .frame(height: 3)

            // Play / Stop
            HStack {
                Button(action: togglePlayback) {
                    HStack(spacing: 8) {
                        Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text(isPlaying ? "Stop" : "Play")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: "#7C6FF7"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(Color(hex: "#1E1B3A"))
                    .cornerRadius(10)
                }
                Spacer()
                if let size = audioSize {
                    Text("\(size) KB")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(hex: "#6B6B7A"))
                }
            }
        }
        .padding(20)
        .background(Color(hex: "#12121A"))
        .cornerRadius(20)
        .padding(.bottom, 12)
    }

    // MARK: - Stats Row

    var statsRow: some View {
        HStack(spacing: 12) {
            statBadge(icon: "bolt.fill", value: String(format: "%.2fs", generationTime ?? 0), label: "Generate")
            if let size = audioSize {
                statBadge(icon: "waveform", value: "\(size) KB", label: "File size")
            }
            statBadge(icon: "mic.fill", value: selectedVoice.name, label: "Voice")
        }
        .padding(.bottom, 12)
    }

    // MARK: - Reusable Chips & Badges

    func currencyChip(_ c: String) -> some View {
        Button {
            if selectedCurrency != c {
                clear()
            }
            selectedCurrency = c
        } label: {
            Text(c)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(selectedCurrency == c ? Color(hex: "#7C6FF7") : Color(hex: "#6B6B7A"))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(selectedCurrency == c ? Color(hex: "#1E1B3A") : Color(hex: "#17171F"))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(selectedCurrency == c ? Color(hex: "#7C6FF7").opacity(0.5) : Color.clear, lineWidth: 1)
                )
        }
        .animation(.easeInOut(duration: 0.15), value: selectedCurrency)
    }

    func languageChip(_ lang: LanguageOption) -> some View {
        Button {
            if selectedLanguage.id != lang.id {
                clear()
            }
            selectedLanguage = lang
        } label: {
            HStack(spacing: 6) {
                Text(lang.flag)
                    .font(.system(size: 14))
                Text(lang.label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(selectedLanguage.id == lang.id ? Color(hex: "#7C6FF7") : Color(hex: "#6B6B7A"))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(selectedLanguage.id == lang.id ? Color(hex: "#1E1B3A") : Color(hex: "#17171F"))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selectedLanguage.id == lang.id ? Color(hex: "#7C6FF7").opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .animation(.easeInOut(duration: 0.15), value: selectedLanguage.id)
    }

    func voiceChip(_ v: VoiceOption) -> some View {
        Button {
            if selectedVoice.name != v.name {
                clear()
            }
            selectedVoice = v
        } label: {
            HStack(spacing: 8) {
                Image(systemName: v.gender == "Female" ? "person.fill" : "person.fill")
                    .font(.system(size: 12))
                    .foregroundColor(selectedVoice.name == v.name ? Color(hex: "#7C6FF7") : Color(hex: "#6B6B7A"))
                VStack(alignment: .leading, spacing: 1) {
                    Text(v.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(selectedVoice.name == v.name ? .white : Color(hex: "#6B6B7A"))
                    Text(v.gender)
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#6B6B7A"))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(selectedVoice.name == v.name ? Color(hex: "#1E1B3A") : Color(hex: "#17171F"))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selectedVoice.name == v.name ? Color(hex: "#7C6FF7").opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .animation(.easeInOut(duration: 0.15), value: selectedVoice.name)
    }

    func statBadge(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#7C6FF7"))
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "#6B6B7A"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(hex: "#12121A"))
        .cornerRadius(12)
    }

    func label(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(Color(hex: "#6B6B7A"))
            .kerning(1.2)
    }

    // MARK: - Helpers

    var currencySymbol: String {
        switch selectedCurrency {
        case "USD": return "$"
        case "KHR": return "៛"
        case "THB": return "฿"
        case "EUR": return "€"
        default:    return "$"
        }
    }

    func waveBarHeight(index: Int) -> CGFloat {
        let base: [CGFloat] = [8,14,20,28,18,32,22,12,36,24,16,30,20,38,26,18,34,22,14,28,20,32,16,24,30,18,22,12]
        let h = base[index % base.count]
        return isPlaying ? h : h * 0.4
    }

    func barColor(index: Int) -> Color {
        let progress = Double(index) / 28.0
        if progress <= playbackProgress {
            return Color(hex: "#7C6FF7")
        }
        return Color(hex: "#2A2A38")
    }

    // MARK: - Playback

    func togglePlayback() {
        guard let data = audioData else { return }
        if isPlaying {
            audioPlayer?.stop()
            isPlaying = false
            playbackTimer?.invalidate()
            playbackProgress = 0
        } else {
            playAudio(data: data)
        }
    }

    func playAudio(data: Data) {
        do {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("speech_\(UUID().uuidString).wav")
            try data.write(to: tempURL)
            audioPlayer = try AVAudioPlayer(contentsOf: tempURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
            startProgressTimer()
        } catch {
            errorMessage = "Playback error: \(error.localizedDescription)"
            showError = true
        }
    }

    func startProgressTimer() {
        playbackTimer?.invalidate()
        playbackProgress = 0
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            guard let player = audioPlayer else { return }
            if player.isPlaying {
                playbackProgress = player.currentTime / player.duration
            } else {
                isPlaying = false
                playbackProgress = 0
                playbackTimer?.invalidate()
            }
        }
    }

    // MARK: - API Call

    func generateTrxSpeech() {
        Task {
            do {
                try validateAmount()
            } catch {
                clear()
                errorMessage = error.localizedDescription
                showError = true
                return
            }
            do {
                await MainActor.run { isLoading = true; audioData = nil }
                let start = Date()
                let data = try await SpeechService.shared.generateSpeech(
                    voiceName: selectedVoice.id,
                    languageCode: selectedLanguage.id,
                    trxAmount: amount,
                    trxCurrency: selectedCurrency
                )
                let elapsed = Date().timeIntervalSince(start)
                await MainActor.run {
                    isLoading = false
                    generationTime = elapsed
                    audioData = data
                    audioSize = data.count / 1024
                    playAudio(data: data)
                }
                
            }catch {
                clear()
                errorMessage = error.localizedDescription
                showError = true
            }
            
        }
    }
    
    func clear(){
        isLoading = false
        generationTime = nil
        audioData = nil
        audioSize = nil
    }
    func validateAmount() throws {
        guard selectedCurrency == "KHR" else { return }

        if amount.contains(".") {
            throw AmountError.hasDecimal
        }

        guard let value = Double(amount), value >= 100 else {
            throw AmountError.belowMinimum
        }
    }
}

