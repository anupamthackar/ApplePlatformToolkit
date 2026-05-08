import SwiftUI
import ToolkitCrypto

@MainActor
struct CryptoDemoView: View {
    @State private var selectedScenario: CryptoScenario = .encryption
    
    var body: some View {
        List {
            Picker("Scenario", selection: $selectedScenario) {
                ForEach(CryptoScenario.allCases, id: \.self) { scenario in
                    Text(scenario.rawValue).tag(scenario)
                }
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)
            
            switch selectedScenario {
            case .encryption:
                EncryptionSection()
            case .hashing:
                HashingSection()
            case .hmac:
                HMACSection()
            case .keys:
                KeyManagementSection()
            }
        }
        .navigationTitle("Crypto Section")
    }
}

enum CryptoScenario: String, CaseIterable {
    case encryption = "Encrypt"
    case hashing = "Hash"
    case hmac = "HMAC"
    case keys = "Keys"
}

// MARK: - Encryption Section
struct EncryptionSection: View {
    @State private var text = "Sensitive Information"
    @State private var algorithm: EncryptionAlgorithm = .aesGcm
    @State private var encryptedData: CryptoResult?
    @State private var decryptedText = ""
    @State private var key = CryptoManager.shared.generateKey()
    
    var body: some View {
        Section("Symmetric Encryption") {
            TextField("Input Text", text: $text)
            
            Picker("Algorithm", selection: $algorithm) {
                Text("AES-GCM").tag(EncryptionAlgorithm.aesGcm)
                Text("ChaChaPoly").tag(EncryptionAlgorithm.chachaPoly)
            }
            
            Button("Execute Encrypt/Decrypt Cycle") {
                runCycle()
            }
            .buttonStyle(.borderedProminent)
        }
        
        if let result = encryptedData {
            Section("Encryption Result") {
                LabeledContent("Algorithm", value: result.algorithm)
                LabeledContent("Size", value: "\(result.data.count) bytes")
                VStack(alignment: .leading) {
                    Text("Ciphertext (Hex):")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(result.encodedHex)
                        .font(.system(.caption, design: .monospaced))
                }
            }
            
            Section("Decryption Result") {
                Text(decryptedText)
                    .bold()
                    .foregroundColor(.green)
            }
        }
    }
    
    func runCycle() {
        Task {
            do {
                let data = Data(text.utf8)
                let result = try await CryptoManager.shared.encrypt(data, using: algorithm, key: key)
                self.encryptedData = result
                
                let decrypted = try await CryptoManager.shared.decrypt(result.data, using: algorithm, key: key)
                self.decryptedText = String(data: decrypted.data, encoding: .utf8) ?? "Decode error"
            } catch {
                self.decryptedText = "Error: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Hashing Section
struct HashingSection: View {
    @State private var text = "Password123"
    @State private var algorithm: CryptoHashAlgorithm = .sha256
    @State private var result: CryptoResult?
    
    var body: some View {
        Section("Secure Hashing") {
            TextField("Data to Hash", text: $text)
            
            Picker("Algorithm", selection: $algorithm) {
                Text("SHA-256").tag(CryptoHashAlgorithm.sha256)
                Text("SHA-384").tag(CryptoHashAlgorithm.sha384)
                Text("SHA-512").tag(CryptoHashAlgorithm.sha512)
            }
            
            Button("Compute Hash") {
                result = CryptoManager.shared.hash(string: text, algorithm: algorithm)
            }
        }
        
        if let result {
            Section("Hash Result") {
                LabeledContent("Length", value: "\(result.data.count * 8) bits")
                VStack(alignment: .leading) {
                    Text("Digest (Hex):")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(result.encodedHex)
                        .font(.system(.caption, design: .monospaced))
                }
            }
        }
    }
}

// MARK: - HMAC Section
struct HMACSection: View {
    @State private var message = "Official Message"
    @State private var key = "secret-key"
    @State private var result: CryptoResult?
    @State private var verification: Bool?
    
    var body: some View {
        Section("Message Authentication (HMAC)") {
            TextField("Message", text: $message)
            TextField("Secret Key", text: $key)
            
            Button("Generate HMAC") {
                let keyData = Data(key.utf8)
                result = CryptoManager.shared.sign(Data(message.utf8), key: keyData)
                verification = nil
            }
        }
        
        if let result {
            Section("HMAC Result") {
                Text(result.encodedHex)
                    .font(.system(.caption, design: .monospaced))
                
                Button("Verify Signature") {
                    verification = CryptoManager.shared.verifySignature(
                        Data(message.utf8),
                        signature: result.data,
                        key: Data(key.utf8)
                    )
                }
                
                if let verification {
                    Label(verification ? "Valid" : "Invalid", systemImage: verification ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(verification ? .green : .red)
                }
            }
        }
    }
}

// MARK: - Key Section
struct KeyManagementSection: View {
    @State private var password = ""
    @State private var derivedKey: String = ""
    
    var body: some View {
        Section("Key Derivation (PBKDF2)") {
            SecureField("Enter Password", text: $password)
            Button("Derive 256-bit Key") {
                let key = CryptoManager.shared.deriveKey(from: password)
                derivedKey = key.map { String(format: "%02x", $0) }.joined()
            }
            
            if !derivedKey.isEmpty {
                VStack(alignment: .leading) {
                    Text("Derived Key:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(derivedKey)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(2)
                }
            }
        }
        
        Section("Utilities") {
            Button("Generate Random Bytes") {
                let bytes = CryptoManager.shared.secureRandomBytes(count: 32)
                print("Random: \(bytes.map { String(format: "%02x", $0) }.joined())")
            }
        }
    }
}
