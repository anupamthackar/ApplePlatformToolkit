import SwiftUI
import ToolkitNetworking

@MainActor
struct NetworkingDemoView: View {
    @State private var selectedScenario: NetworkScenario = .requests
    
    var body: some View {
        List {
            Picker("Scenario", selection: $selectedScenario) {
                ForEach(NetworkScenario.allCases, id: \.self) { scenario in
                    Text(scenario.rawValue).tag(scenario)
                }
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)
            
            switch selectedScenario {
            case .requests:
                RESTRequestSection()
            case .downloads:
                DownloadSection()
            case .interceptors:
                InterceptorSection()
            }
        }
        .navigationTitle("Networking Section")
    }
}

enum NetworkScenario: String, CaseIterable {
    case requests = "REST"
    case downloads = "Files"
    case interceptors = "Config"
}

// MARK: - REST Request Section
struct RESTRequestSection: View {
    @State private var url = "https://api.github.com/zen"
    @State private var method: HTTPMethod = .get
    @State private var requestBody = ""
    @State private var responseStatus: Int?
    @State private var responseBody = ""
    @State private var isLoading = false
    
    enum HTTPMethod: String, CaseIterable {
        case get = "GET", post = "POST", put = "PUT", delete = "DELETE"
    }
    
    var body: some View {
        Section("Request Configuration") {
            TextField("URL", text: $url)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .disableAutocorrection(true)
            
            Picker("Method", selection: $method) {
                ForEach(HTTPMethod.allCases, id: \.self) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            
            if method == .post || method == .put {
                VStack(alignment: .leading) {
                    Text("JSON Body")
                        .font(.caption)
                    TextEditor(text: $requestBody)
                        .frame(height: 100)
                        .font(.system(.caption, design: .monospaced))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                }
            }
            
            Button("Execute Request") {
                execute()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)
        }
        
        Section("Response") {
            if isLoading {
                ProgressView()
            } else {
                if let status = responseStatus {
                    LabeledContent("Status Code", value: "\(status)")
                        .foregroundColor(status < 300 ? .green : .red)
                }
                
                ScrollView {
                    Text(responseBody)
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 100, maxHeight: 300)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    func execute() {
        guard let requestURL = URL(string: url) else {
            responseBody = "Invalid URL"
            return
        }
        
        isLoading = true
        Task {
            do {
                var request = URLRequest(url: requestURL)
                request.httpMethod = method.rawValue
                
                if (method == .post || method == .put) && !requestBody.isEmpty {
                    request.httpBody = requestBody.data(using: .utf8)
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                }
                
                let (data, status) = try await APIClient.shared.executeRaw(request)
                responseStatus = status
                responseBody = String(data: data, encoding: .utf8) ?? "Binary Data (\(data.count) bytes)"
            } catch {
                responseBody = "Error: \(error.localizedDescription)"
                responseStatus = 0
            }
            isLoading = false
        }
    }
}

// MARK: - Download Section
struct DownloadSection: View {
    @State private var downloadURL = "https://raw.githubusercontent.com/Alamofire/Alamofire/master/logo.png"
    @State private var progress: Double = 0
    @State private var status = "Ready"
    
    var body: some View {
        Section("File Operations") {
            TextField("File URL", text: $downloadURL)
            Button("Start Download") {
                startDownload()
            }
            
            Text(status)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    func startDownload() {
        guard let url = URL(string: downloadURL) else { return }
        status = "Downloading..."
        Task {
            do {
                let destination = FileManager.default.temporaryDirectory.appendingPathComponent("downloaded_file.tmp")
                try await APIClient.shared.download(from: url, to: destination)
                status = "Success! Saved to \(destination.lastPathComponent)"
            } catch {
                status = "Error: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Interceptor Section
struct InterceptorSection: View {
    var body: some View {
        Section("Network Configuration") {
            let config = APIClient.shared.config
            LabeledContent("Logging", value: config.loggingEnabled ? "Enabled" : "Disabled")
            LabeledContent("Max Retries", value: "\(config.retryPolicy.maxAttempts)")
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Active Interceptors")
                    .font(.headline)
                ForEach(APIClient.shared.interceptors.indices, id: \.self) { index in
                    Text("\(index + 1). \(String(describing: type(of: APIClient.shared.interceptors[index])))")
                        .font(.caption)
                }
            }
        }
    }
}
