import SwiftUI
import ToolkitFormatter
import ToolkitCore
import ToolkitUI

@MainActor
struct FormatterDemoView: View {
    @State private var inputNumber: Double = 1234567.89
    @State private var inputDate: Date = Date()
    @State private var inputString: String = "toolkit-pipeline-demo"
    @Environment(\.tkTheme) var theme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                TKCard {
                    VStack(alignment: .leading, spacing: 16) {
                        TKSectionHeader("Numeric & Currency")
                        
                        VStack(spacing: 8) {
                            Slider(value: $inputNumber, in: 0...10_000_000)
                                .accentColor(theme.primaryColor)
                            
                            HStack {
                                Text("Value:")
                                    .font(theme.captionFont)
                                    .foregroundColor(theme.textTertiary)
                                TextField("Number", value: $inputNumber, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(.body, design: .monospaced))
                                    .frame(width: 120)
                            }
                        }
                        
                        Divider()
                        
                        Group {
                            FormatRow(label: "Currency (USD)", value: Toolkit.formatter.formatCurrency(inputNumber, code: "USD"))
                            FormatRow(label: "Currency (EUR)", value: Toolkit.formatter.formatCurrency(inputNumber, code: "EUR"))
                            FormatRow(label: "Abbreviated", value: Toolkit.formatter.abbreviateNumber(inputNumber))
                        }
                    }
                }
                
                TKCard {
                    VStack(alignment: .leading, spacing: 16) {
                        TKSectionHeader("Date & Time")
                        
                        DatePicker("Select Date", selection: $inputDate)
                            .datePickerStyle(.compact)
                            .font(theme.bodyFont)
                        
                        Divider()
                        
                        Group {
                            FormatRow(label: "Medium Style", value: Toolkit.formatter.formatDate(inputDate, style: .medium))
                            FormatRow(label: "Relative", value: Toolkit.formatter.formatRelativeDate(inputDate))
                        }
                    }
                }
                
                TKCard {
                    VStack(alignment: .leading, spacing: 16) {
                        TKSectionHeader("String Pipelines")
                        
                        TKTextField(text: $inputString, placeholder: "Enter text to transform", icon: "terminal")
                        
                        let result = Toolkit.formatter.pipeline()
                            .trim()
                            .uppercase()
                            .execute(inputString)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TRANSFORMED OUTPUT")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(theme.textTertiary)
                            
                            Text(result)
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                .foregroundColor(theme.primaryColor)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(theme.primaryColor.opacity(0.05))
                                .cornerRadius(12)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Data Formatting")
        .background(theme.backgroundColor.ignoresSafeArea())
        .tkThemed()
    }
}

struct FormatRow: View {
    let label: String
    let value: String
    @Environment(\.tkTheme) var theme
    
    var body: some View {
        HStack {
            Text(label)
                .font(theme.bodyFont)
                .foregroundColor(theme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(theme.textPrimary)
        }
    }
}
