//
//  SpeechToTextService.swift
//  SpeechToText
//
//  Created by legin098 on 10/10/24.
//

import AVFoundation
import Foundation
import Speech

let key = ""
var targetLanguage = "Vietnamese"

class SpeechToTextService: SpeechToTextServiceProtocol {
    private var accumulatedText: String = ""
    private var accumulatedTranslatedText: String = ""
    
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var recognizer: SFSpeechRecognizer?
    
    /// Initializes a new instance of the speech recognition service with the provided locale identifier.
    /// - Parameter localeIdentifier: The locale identifier to use (defaults to the device's current locale).
    init(localeIdentifier: String = Locale.current.identifier) {
        self.recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier))
    }
    
    /// Requests permissions and verifies the availability of the speech recognizer.
    /// - Throws: `RecognizerError` if the recognizer is unavailable or if the necessary permissions are not granted.
    func authorize() async throws {
        guard let recognizer = self.recognizer else {
            throw RecognizerError.recognizerUnavailable
        }
        
        let hasAuthorization = await SFSpeechRecognizer.hasAuthorizationToRecognize()
        guard hasAuthorization else {
            throw RecognizerError.notAuthorizedToRecognize
        }
        
        let hasRecordPermission = await AVAudioSession.sharedInstance().hasPermissionToRecord()
        guard hasRecordPermission else {
            throw RecognizerError.notPermittedToRecord
        }
        
        if !recognizer.isAvailable {
            throw RecognizerError.recognizerUnavailable
        }
    }
    
    func updateSourceLanguage(_ localeIdentifier: String) {
        self.recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier))
    }
    
    func updateTargetLanguage(_ localeIdentifier: String) {
        targetLanguage = localeIdentifier
    }
    
    deinit {
        reset()
    }
    
    /// Starts the speech-to-text transcription process.
    /// - Returns: An `AsyncThrowingStream` that emits strings of transcribed text.
    @MainActor
    func transcribe() -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let (audioEngine, request) = try Self.prepareEngine()
                    self.audioEngine = audioEngine
                    self.request = request
                    
                    guard let recognizer = self.recognizer else {
                        throw RecognizerError.recognizerUnavailable
                    }
                    
                    self.task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                        guard let self = self else {
                            return
                        }
                        
                        if let error = error {
                            continuation.finish(throwing: error)
                            self.reset()
                            return
                        }
                        
                        if let result = result {
                            let newText = result.bestTranscription.formattedString
                            continuation.yield(accumulatedText + newText)
                            
                            if result.speechRecognitionMetadata != nil {
                                self.accumulatedText += newText + " "
                            }
                            
                            if result.isFinal {
                                continuation.finish()
                                self.reset()
                            }
                        }
                    }
                } catch {
                    continuation.finish(throwing: error)
                    self.reset()
                }
            }
        }
    }
    
    /// Stops the transcription process and releases associated resources.
    func stopTranscribing() {
        reset()
    }
    
    /// Resets and releases the resources used by the speech recognition service.
    func reset() {
        task?.cancel()
        task = nil
        audioEngine?.stop()
        audioEngine = nil
        request = nil
        accumulatedText = ""
    }
    
    /// Prepares the audio engine and speech recognition request.
    /// - Returns: A tuple containing the configured `AVAudioEngine` and `SFSpeechAudioBufferRecognitionRequest`.
    private static func prepareEngine() throws -> (AVAudioEngine, SFSpeechAudioBufferRecognitionRequest) {
        let audioEngine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.addsPunctuation = true
        request.taskHint = .dictation
        request.shouldReportPartialResults = true
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        return (audioEngine, request)
    }
}


struct OpenAIRequest: Codable {
    let model: String
    let messages: [[String: String]]
}

struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
}

func summarize(input: String, targetLanguage: String, completion: @escaping (String?) -> Void) {
    let url = URL(string: "https://api.openai.com/v1/chat/completions")!
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let prompt = """
    Summarize the following content clearly and professionally:  

    "\(input)"  

    - **Capture the main ideas and key details concisely.**  
    - **Maintain a formal and objective tone.**  
    - **Avoid unnecessary details and repetition.**  
    - **Ensure clarity and readability.**  
    - **Ensure the summary is coherent and logically organized.**
    - **Structure the summary in a way that makes sense.**
    Provide only the summarized text as the output.
    """
    
    let requestBody = OpenAIRequest(
        model: "gpt-4o-mini",
        messages: [["role": "user", "content": prompt]]
    )
    
    request.httpBody = try? JSONEncoder().encode(requestBody)
    
    URLSession.shared.dataTask(with: request) { data, _, error in
        guard let data = data, error == nil else {
            completion(nil)
            return
        }
        
        if let response = try? JSONDecoder().decode(OpenAIResponse.self, from: data) {
            if let rawText = response.choices.first?.message.content {
                completion(rawText)
            }
        } else {
            completion(nil)
        }
    }.resume()
}


func translateText(input: String, completion: @escaping (String?) -> Void) {
    let url = URL(string: "https://api.openai.com/v1/chat/completions")!
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let prompt = """
    Translate the following text into \(targetLanguage): "\(input)"  
    - **Only translate new phrases or sentences** that have not been translated before and have meaning.  
    - **Respond only with the newly translated sentence(s), without extra text or formatting.**  
    """
    
    let requestBody = OpenAIRequest(
        model: "gpt-4o-mini",
        messages: [["role": "user", "content": prompt]]
    )
    
    request.httpBody = try? JSONEncoder().encode(requestBody)
    
    URLSession.shared.dataTask(with: request) { data, _, error in
        guard let data = data, error == nil else {
            completion(nil)
            return
        }
        
        if let response = try? JSONDecoder().decode(OpenAIResponse.self, from: data) {
            if let rawText = response.choices.first?.message.content {
                completion(rawText)
            }
        } else {
            completion(nil)
        }
    }.resume()
}
