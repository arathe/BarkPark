import SwiftUI

struct FeedDebugView: View {
    @State private var rawResponse = ""
    @State private var decodingError = ""
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Feed Debug Tool")
                    .font(.largeTitle)
                    .padding(.bottom)
                
                // Test endpoints
                Section(header: Text("Test Endpoints").font(.headline)) {
                    Button("Test Mock Feed") {
                        testMockFeed()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Test Raw Database") {
                        testRawDatabase()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Test Actual Feed") {
                        testActualFeed()
                    }
                    .buttonStyle(.bordered)
                }
                
                if isLoading {
                    ProgressView()
                        .padding()
                }
                
                // Raw Response
                if !rawResponse.isEmpty {
                    Section(header: Text("Raw Response").font(.headline)) {
                        Text(rawResponse)
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                // Decoding Error
                if !decodingError.isEmpty {
                    Section(header: Text("Decoding Error").font(.headline)) {
                        Text(decodingError)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
    }
    
    func testMockFeed() {
        isLoading = true
        rawResponse = ""
        decodingError = ""
        
        Task {
            do {
                let url = URL(string: "https://barkpark-production.up.railway.app/api/test/feed/debug")!
                let (data, _) = try await URLSession.shared.data(from: url)
                
                // Show raw response
                if let jsonString = String(data: data, encoding: .utf8) {
                    await MainActor.run {
                        rawResponse = jsonString
                    }
                }
                
                // Try to decode
                _ = try JSONDecoder.barkParkDecoder.decode(FeedResponse.self, from: data)
                
                await MainActor.run {
                    decodingError = "✅ Successfully decoded!"
                }
            } catch let error as DecodingError {
                await MainActor.run {
                    decodingError = describeDecodingError(error)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    decodingError = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    func testRawDatabase() {
        isLoading = true
        rawResponse = ""
        decodingError = ""
        
        Task {
            do {
                let url = URL(string: "https://barkpark-production.up.railway.app/api/test/feed/raw")!
                let (data, _) = try await URLSession.shared.data(from: url)
                
                if let jsonString = String(data: data, encoding: .utf8) {
                    await MainActor.run {
                        rawResponse = jsonString
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    decodingError = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    func testActualFeed() {
        isLoading = true
        rawResponse = ""
        decodingError = ""
        
        Task {
            do {
                let response = try await APIService.shared.getFeed()
                await MainActor.run {
                    rawResponse = "✅ Success! Got \(response.posts.count) posts"
                    isLoading = false
                }
            } catch let error as DecodingError {
                await MainActor.run {
                    decodingError = describeDecodingError(error)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    decodingError = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    func describeDecodingError(_ error: DecodingError) -> String {
        switch error {
        case .typeMismatch(let type, let context):
            return "Type mismatch: Expected \(type)\nPath: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))\nDebug: \(context.debugDescription)"
        case .valueNotFound(let type, let context):
            return "Value not found: \(type)\nPath: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))\nDebug: \(context.debugDescription)"
        case .keyNotFound(let key, let context):
            return "Key not found: \(key.stringValue)\nPath: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))\nDebug: \(context.debugDescription)"
        case .dataCorrupted(let context):
            return "Data corrupted\nPath: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))\nDebug: \(context.debugDescription)"
        @unknown default:
            return "Unknown decoding error: \(error)"
        }
    }
}

#Preview {
    FeedDebugView()
}