import SwiftUI
import ToolkitCompression
import ToolkitCore
import ToolkitUI

@MainActor
struct CompressionDemoView: View {
    @State private var inputString = "The Apple Platform Toolkit is a collection of high-performance, modular components designed for enterprise-grade iOS and macOS development. It provides standard infrastructure for every modern app."
    @State private var compressedData: Data?
    @State private var decompressedString: String?
    @State private var isLoading = false
    @State private var ratioText = "N/A"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                TKCard {
                    VStack(alignment: .leading, spacing: 12) {
                        TKSectionHeader("Input Data")
                        TextEditor(text: $inputString)
                            .frame(height: 100)
                            .padding(8)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                        
                        TKButton(config: TKButtonConfig(title: "Compress Data", style: .primary)) {
                            performCompression()
                        }
                    }
                }
                
                if let data = compressedData {
                    TKCard {
                        VStack(alignment: .leading, spacing: 12) {
                            TKSectionHeader("Compression Result")
                            HStack {
                                LabeledContent("Original Size", value: "\(inputString.data(using: .utf8)?.count ?? 0) bytes")
                                Spacer()
                                TKBadge("Ratio: \(ratioText)", color: .green)
                            }
                            LabeledContent("Compressed Size", value: "\(data.count) bytes")
                            
                            TKButton(config: TKButtonConfig(title: "Decompress Data", style: .secondary)) {
                                performDecompression()
                            }
                        }
                    }
                }
                
                if let result = decompressedString {
                    TKCard {
                        VStack(alignment: .leading, spacing: 12) {
                            TKSectionHeader("Decompressed Output")
                            Text(result)
                                .font(.system(.body, design: .monospaced))
                                .padding(8)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Compression")
        .tkThemed()
    }
    
    private func performCompression() {
        guard let data = inputString.data(using: .utf8) else { return }
        Task {
            isLoading = true
            do {
                let manager = CompressionManager.shared
                let result = try await manager.compress(data)
                compressedData = result.data
                ratioText = manager.formatRatio(result)
            } catch {
                Toolkit.ui.showError("Compression failed: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
    
    private func performDecompression() {
        guard let data = compressedData else { return }
        Task {
            isLoading = true
            do {
                let manager = CompressionManager.shared
                let result = try await manager.decompress(data, originalSize: inputString.data(using: .utf8)?.count ?? 0)
                decompressedString = String(data: result.data, encoding: .utf8)
            } catch {
                Toolkit.ui.showError("Decompression failed: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
}
