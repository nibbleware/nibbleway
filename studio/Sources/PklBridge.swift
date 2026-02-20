import Foundation

struct PklPolicy: Codable {
    let id: String
    let description: String
    let enabled: Bool
    let scrubbingRules: [ScrubbingRule]
    
    enum CodingKeys: String, CodingKey {
        case id, description, enabled
        case scrubbingRules = "scrubbing_rules"
    }
}

struct ScrubbingRule: Codable {
    let pattern: String
    let replacement: String
}

class PklBridge: ObservableObject {
    @Published var currentPolicy: PklPolicy?
    
    func loadPolicy(from path: String) {
        // Placeholder for Pkl evaluation logic
        // In the future, this would call the `pkl` binary or use a native evaluator.
        self.currentPolicy = PklPolicy(
            id: "default-safety",
            description: "Default PII scrubbing",
            enabled: true,
            scrubbingRules: [
                ScrubbingRule(pattern: "[0-9]{3}-[0-9]{2}-[0-9]{4}", replacement: "[SSN-REDACTED]")
            ]
        )
    }
    
    func scrub(_ text: String) -> String {
        guard let policy = currentPolicy else { return text }
        var scrubbed = text
        for rule in policy.scrubbingRules {
            if let regex = try? NSRegularExpression(pattern: rule.pattern, options: []) {
                let range = NSRange(location: 0, length: scrubbed.utf16.count)
                scrubbed = regex.stringByReplacingMatches(in: scrubbed, options: [], range: range, withTemplate: rule.replacement)
            }
        }
        return scrubbed
    }
}
