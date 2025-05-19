//
//  SpeechToTextView.swift
//  SpeechToText
//
//  Created by legin098 on 10/10/24.
//

import SwiftUI

private enum Layout {
    enum Container {
        static let background: Color = .black
        static let fontColor: Color = .white
        static let spacing: CGFloat = 20.0
    }
    enum ScrollContainer {
        static let height: CGFloat = 150.0
        static let borderWidth: CGFloat = 1.0
        static let borderColor: Color = .white
    }
    enum RecordButton {
        static let startRecordingColor: Color = .green.opacity(0.3)
        static let stopRecordingColor: Color = .red.opacity(0.3)
        static let cornerRadius: CGFloat = 10.0
    }
}

struct SpeechToTextView: View {
    @StateObject private var viewModel = SpeechToTextViewModel(speechToTextService: SpeechToTextService())
    @State private var showingSummary = false
    @State private var showingSourceLanguageMenu = false
    @State private var showingTargetLanguageMenu = false
    
    // Language options
    let languages: [(code: String, name: String)] = [
        ("en", "English"),
//        ("es", "Spanish"),
//        ("fr", "French"),
//        ("de", "German"),
//        ("it", "Italian"),
        ("ja", "Japanese"),
        ("ko", "Korean"),
        ("vn", "Vietnamese")
//        ("zh", "Chinese"),
//        ("ru", "Russian"),
//        ("ar", "Arabic"),
//        ("hi", "Hindi"),
//        ("pt", "Portuguese")
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(#colorLiteral(red: 0.1, green: 0.1, blue: 0.3, alpha: 1)), Color(#colorLiteral(red: 0.2, green: 0.2, blue: 0.5, alpha: 1))]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Header
                Text("Speech To Text")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top)
                
                // Language selection
                VStack(spacing: 10) {
                    // Source language
                    HStack {
                        Text("Source Language")
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            showingSourceLanguageMenu.toggle()
                        }) {
                            HStack {
                                Text(viewModel.sourceLanguage)
                                    .foregroundColor(.white)
                                
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .popover(isPresented: $showingSourceLanguageMenu, arrowEdge: .top) {
                            LanguagePickerView(
                                languages: languages,
                                selectedLanguageCode: viewModel.sourceLanguageCode,
                                onSelect: { code, name in
                                    viewModel.sourceLanguageCode = code
                                    viewModel.sourceLanguageName = name
                                    showingSourceLanguageMenu = false
                                }
                            )
                            .frame(width: 200, height: 300)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Target language
                    HStack {
                        Text("Target Language")
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            showingTargetLanguageMenu.toggle()
                        }) {
                            HStack {
                                Text(viewModel.targetLanguage)
                                    .foregroundColor(.white)
                                
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .popover(isPresented: $showingTargetLanguageMenu, arrowEdge: .top) {
                            LanguagePickerView(
                                languages: languages,
                                selectedLanguageCode: viewModel.targetLanguageCode,
                                onSelect: { code, name in
                                    viewModel.targetLanguageCode = code
                                    viewModel.targetLanguageName = name
                                    showingTargetLanguageMenu = false
                                }
                            )
                            .frame(width: 200, height: 300)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Auto translate toggle
                    HStack {
                        Text("Auto Translate")
                            .foregroundColor(.white)
                        Spacer()
                        Toggle("", isOn: $viewModel.isAutoTranslate)
                            .labelsHidden()
                            .tint(Color.blue.opacity(0.8))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Transcript panel
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Transcript")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        Text(viewModel.sourceLanguageName)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(4)
                    }
                    .padding(.horizontal)
                    
                    ScrollView {
                        Text(viewModel.transcript.isEmpty ? "Your speech will appear here..." : viewModel.transcript)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(viewModel.transcript.isEmpty ? .gray : .white)
                    }
                    .frame(height: 120)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal)
                }
                
                // Translation panel
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Translation")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        Text(viewModel.targetLanguageName)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(4)
                    }
                    .padding(.horizontal)
                    
                    ScrollView {
                        Text(viewModel.translatedString.isEmpty ? "Translation will appear here..." : viewModel.translatedString)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(viewModel.translatedString.isEmpty ? .gray : .white)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.translatedString)
                    }
                    .frame(height: 120)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 15) {
                    if !viewModel.isAutoTranslate {
                        ActionButton(
                            title: "Translate",
                            icon: "arrow.left.arrow.right",
                            isLoading: viewModel.isTranslating,
                            action: viewModel.translate
                        )
                    }
                    
                    ActionButton(
                        title: "Summary",
                        icon: "doc.text",
                        isLoading: viewModel.isSummarizing,
                        action: {
                            viewModel.summarize()
                            showingSummary = true
                        }
                    )
                }
                .padding(.horizontal)
                
                // Record button
                Button(action: toggleRecord) {
                    HStack(spacing: 12) {
                        Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                        Text(viewModel.isRecording ? "Stop Recording" : "Start Recording")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 15)
                    .padding(.horizontal, 25)
                    .frame(maxWidth: .infinity)
                    .background(backgroundView())
                    .cornerRadius(30)
                    .shadow(color: viewModel.isRecording ? Color.red.opacity(0.4) : Color.purple.opacity(0.4), radius: 10, x: 0, y: 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding()
            
            // Summary modal
            if showingSummary && !viewModel.summary.isEmpty {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showingSummary = false
                    }
                
                VStack(spacing: 15) {
                    Text("Summary")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    ScrollView {
                        Text(viewModel.summary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(.white)
                    }
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(15)
                    
                    Button("Close") {
                        showingSummary = false
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 30)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
                .padding(25)
                .background(
                    BlurView(style: .systemThinMaterialDark)
                        .cornerRadius(20)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .frame(width: UIScreen.main.bounds.width * 0.85)
                .transition(.scale)
                .animation(.spring(), value: showingSummary)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button("Reset") {
                viewModel.clear()
            }
            .foregroundColor(.white)
            .font(.title2)
            .padding()
        }
    }
    
    @ViewBuilder
    func backgroundView() -> some View {
        if viewModel.isRecording {
            Color.red.opacity(0.8)
        } else {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple]),
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    private func toggleRecord() {
        if viewModel.isRecording {
            viewModel.stopRecording()
        } else {
            viewModel.startRecording()
        }
    }
}

// Language Picker View
struct LanguagePickerView: View {
    let languages: [(code: String, name: String)]
    let selectedLanguageCode: String
    let onSelect: (String, String) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(languages, id: \.code) { language in
                    Button(action: {
                        onSelect(language.code, language.name)
                    }) {
                        HStack {
                            Text(language.name)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if language.code == selectedLanguageCode {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 15)
                        .background(language.code == selectedLanguageCode ? Color.blue.opacity(0.1) : Color.clear)
                    }
                    
                    Divider()
                        .padding(.horizontal, 5)
                }
            }
        }
        .background(Color(.clear))
    }
}

// Helper Views
struct ActionButton: View {
    var title: String
    var icon: String
    var isLoading: Bool = false
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.1))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .foregroundColor(.white)
        .disabled(isLoading)
    }
}

// Blur effect for the modal
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

// Extension to SpeechToTextViewModel - You'll need to add these properties to your ViewModel
extension SpeechToTextViewModel {
    // Add these properties to your actual ViewModel class
    var sourceLanguageCode: String {
        get { UserDefaults.standard.string(forKey: "sourceLanguageCode") ?? "en" }
        set {
            UserDefaults.standard.set(newValue, forKey: "sourceLanguageCode")
            // Update your speech recognition service with new language
            speechToTextService.updateSourceLanguage(newValue)
        }
    }
    
    var sourceLanguageName: String {
        get { UserDefaults.standard.string(forKey: "sourceLanguageName") ?? "English" }
        set {
            sourceLanguage = newValue
            UserDefaults.standard.set(newValue, forKey: "sourceLanguageName")
        }
    }
    
    var targetLanguageCode: String {
        get { UserDefaults.standard.string(forKey: "targetLanguageCode") ?? "es" }
        set {
            UserDefaults.standard.set(newValue, forKey: "targetLanguageCode")
            // Update your translation service with new language
        }
    }
    
    var targetLanguageName: String {
        get { UserDefaults.standard.string(forKey: "targetLanguageName") ?? "English" }
        set {
            targetLanguage = newValue
            UserDefaults.standard.set(newValue, forKey: "targetLanguageName")
            speechToTextService.updateTargetLanguage(targetLanguage)
        }
    }
}

#Preview {
    SpeechToTextView()
}
