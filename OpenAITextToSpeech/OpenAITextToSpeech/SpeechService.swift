//
//  SpeechService.swift
//  OpenAITextToSpeech
//
//  Created by Houleng.LY on 28/6/26.
//


import Foundation

struct SpeechRequest: Codable {
    let message: String
    let language: String
    let voiceId: Int
    let speechModel: String
}

struct TrxSpeechRequest: Codable {
    let trxAmount: String
    let trxCurrency: String
}

struct SpeechResponse: Codable {
    let status: String
    let message: String
    let language: String
    let voiceId: Int
    let speechModel: String
}

class SpeechService {
    static let shared = SpeechService()
    private let baseURL = "https://trx-voice-alert-tts.vercel.app"
    
    func generateSpeech(
        voiceName: String,
        languageCode: String,
        trxAmount: String,
        trxCurrency: String
    ) async throws -> Data {
        
        print("\(baseURL)/openai/api/v1/speech/\(voiceName)/\(languageCode)/generate")

        guard let url = URL(string: "\(baseURL)/openai/api/v1/speech/\(voiceName)/\(languageCode)/generate") else {
            throw URLError(.badURL)
        }

        let body = TrxSpeechRequest(
            trxAmount: trxAmount,
            trxCurrency: trxCurrency
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer ...", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)
        

        let (data, response) = try await URLSession.shared.data(for: request)
        
        

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        print("Trx audio data size: \(data.count) bytes")

        return data
    }
    
    func download(from audioUrl: String) async throws -> Data {
        guard let url = URL(string: audioUrl) else {
            throw NSError(domain: "SpeechService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL string."])
        }
        let downloadDate = Date()
        let (data, _) = try await URLSession.shared.data(from: url)
        print("Download file size: \(data.count/1000) KB, took: \(Date().timeIntervalSince(downloadDate))s")
        return data
    }
    
}
