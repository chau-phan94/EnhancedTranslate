//
//  SpeechToTextViewModel.swift
//  SpeechToText
//
//  Created by legin098 on 10/10/24.
//

import Foundation
import SwiftUI
import Combine

final class SpeechToTextViewModel: ObservableObject {
    @Published var transcript: String = ""
    @Published var translatedString: String = ""
    @Published var isRecording = false
    @Published var errorMessage: String?
    @Published var isTranslating = false
    @Published var isAutoTranslate = false
    @Published var sourceLanguage: String = UserDefaults.standard.string(forKey: "sourceLanguageName") ?? "English"
    @Published var targetLanguage: String = UserDefaults.standard.string(forKey: "targetLanguageName") ?? "Vietnamese"
    @Published var summary: String = ""
    @Published var isSummarizing  = false
    
    let speechToTextService: SpeechToTextService
    
    private var transcriptionTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    private var completedSentences = [String]()
    private var translatedSentences = [String]()
    
    
    init(speechToTextService: SpeechToTextService) {
        self.speechToTextService = speechToTextService
        setupTranslationPipeline()
    }
    
    /// Starts the recording and transcription process.
    /// - Calls the service to authorize the use of voice recognition and begins transcription.
    /// - Updates the `transcript` variable with partial results as they are recognized.
    @MainActor
    func startRecording() {
        guard !isRecording else {
            return
        }
        
        isRecording = true
        
        transcriptionTask = _Concurrency.Task {
            do {
                try await speechToTextService.authorize()
                
                let stream = speechToTextService.transcribe()
                for try await partialResult in stream {
                    self.transcript = partialResult
                }
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func clear() {
        transcript = ""
        translatedString = ""
        summary = ""
    }
    
    func summarize() {
        isSummarizing = true
        SpeechToText.summarize(input: transcript, targetLanguage: targetLanguage) { finalString in
            DispatchQueue.main.async {
                self.isSummarizing = false
                self.summary = finalString ?? ""
            }
        }
    }
    
//    private func setupTranslationPipeline() {
//            $transcript
//                .dropFirst()  // Ignore initial value
//                .filter { _ in self.isAutoTranslate}
//                .removeDuplicates()  // Prevent unnecessary calls if text hasn't changed
//                .throttle(for: .seconds(2), scheduler: DispatchQueue.main, latest: true)  // Wait for user to finish speaking
//                .sink { [weak self] text in
//                    guard let self = self, !text.isEmpty else { return }
//                    translateText(input: text) { translatedText in
//                        DispatchQueue.main.async {
//                            self.translatedString = translatedText ?? ""
//                        }
//                    }
//                }
//                .store(in: &cancellables)
//        }
    
    private func setupTranslationPipeline() {
        $transcript
            .dropFirst()  // Ignore initial value
            .filter { _ in self.isAutoTranslate }
            .removeDuplicates()  // Prevent unnecessary calls if text hasn't changed
            .debounce(for: .seconds(0.7), scheduler: DispatchQueue.main)  // Small pause after user stops speaking
            .scan((previous: "", current: "")) { accumulatedState, newTranscript in
                // Track the previous state and the new state
                let previousText = accumulatedState.current
                return (previous: previousText, current: newTranscript)
            }
            .map { previousText, currentText -> String in
                // Extract only the new content added since last update
                if currentText.hasPrefix(previousText) && previousText.count < currentText.count {
                    return String(currentText.dropFirst(previousText.count))
                }
                return currentText
            }
            .filter { !$0.isEmpty }
            .sink { [weak self] newContent in
                guard let self = self else { return }
                
                // Check if the new content forms a complete sentence
                let endsWithSentenceBreak = newContent.last?.isOneSentenceTerminator ?? false
                
                // Clean up the new content if needed
                var cleanedContent = newContent.trimmingCharacters(in: .whitespaces)
                
                // Translate the new content
                translateText(input: cleanedContent) { translatedText in
                    DispatchQueue.main.async {
                        if let translatedPart = translatedText {
                            // First translation or after a sentence break
                            if self.translatedString.isEmpty {
                                self.translatedString = translatedPart
                            } else {
                                // Append with proper spacing
                                if self.translatedString.last?.isOneSentenceTerminator ?? false {
                                    self.translatedString += " " + translatedPart
                                } else {
                                    // Continue the current sentence
                                    self.translatedString += " " + translatedPart.lowercased(with: .current)
                                }
                            }
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func translate() {
        self.isTranslating = true
        translateText(input: transcript) { [weak self] translatedText in
            guard let self = self, let translatedText = translatedText else { return }
            DispatchQueue.main.async {
                self.isTranslating = false
                self.translatedString = translatedText
            }
        }
    }
//    private func setupTranslationPipeline() {
//        $transcript
//            .dropFirst()
//            .removeDuplicates()
//            .throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: true)
//            .compactMap { [weak self] text -> String? in
//                self?.extractLatestSentence(from: text)
//            }
//            .sink { [weak self] newSentence in
//                self?.translateNewSentence(newSentence)
//            }
//            .store(in: &cancellables)
//    }
    
    /// Extracts the latest fully completed sentence
//    private func extractLatestSentence(from text: String) -> String? {
//        let sentences = text.split { [".", "!", "?"].contains($0) }
//            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
//            .filter { !$0.isEmpty }
//    
//        guard let lastSentence = sentences.last else { return nil }  // No new sentence
//    
//        let lastChar = text.last ?? " "
//        let isComplete = [".", "!", "?"].contains(lastChar)
//    
//        guard isComplete, !completedSentences.contains(lastSentence) else { return nil }
//        
//        print("Extracted sentence: \(lastSentence)")
//    
//        completedSentences.append(lastSentence)  // Store original sentence
//        return lastSentence
//    }
//    
//    /// Translates only the new sentence and merges translations
//    private func translateNewSentence(_ sentence: String) {
//        translateText(input: sentence, targetLanguage: "Vietnamese") { [weak self] translatedText in
//            guard let self = self, let translatedText = translatedText else { return }
//            DispatchQueue.main.async {
//                self.translatedSentences.append(translatedText) // Store translation
//                let joined = self.translatedSentences.joined(separator: " ")
//                self.translatedString = joined
//            }
//        }
//    }
    
    /// Stops the recording and transcription process.
    /// - Ends the background task and resets the recording state.
    @MainActor
    func stopRecording() {
        guard isRecording else {
            return
        }
        isRecording = false
        transcriptionTask?.cancel()
        transcriptionTask = nil
        speechToTextService.stopTranscribing()
    }
}

// Extension to help with sentence detection
extension Character {
    var isOneSentenceTerminator: Bool {
        return self == "." || self == "!" || self == "?"
    }
}
