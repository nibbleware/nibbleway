import AppIntents
import Foundation
// We need to import Models to access ArchitecturalPolicy
// REMOVED: import Models

// Define an AppEnum for the Policy Domain
enum PolicyDomain: String, AppEnum {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Policy Domain"
    static let caseDisplayRepresentations: [PolicyDomain : DisplayRepresentation] = [
        .backend: "Backend Services",
        .frontend: "Frontend UI",
        .database: "Database Systems",
        .networking: "Networking & Connectivity",
        .security: "Security Policies"
    ]

    case backend = "Backend"
    case frontend = "Frontend"
    case database = "Database"
    case networking = "Networking"
    case security = "Security"
}

struct ApplyPolicyIntent: AppIntent {
    static let title: LocalizedStringResource = "Apply Architectural Policy"
    static let description = IntentDescription("Directs the Nibbleway Studio to apply a specific policy to the current project.")

    // Change policyName from String to ArchitecturalPolicy (an AppEntity)
    @Parameter(title: "Policy")
    var policy: ArchitecturalPolicy

    // Change domain from String to PolicyDomain (an AppEnum)
    @Parameter(title: "Domain")
    var domain: PolicyDomain

    static var parameterSummary: some ParameterSummary {
        // Updated summary to reflect new parameter names and types
        Summary("Apply \(\.$policy) to the \(\.$domain) domain")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // This is where we'd link back to the StudioViewModel to trigger orchestration
        return .result(dialog: "Applying \(policy.name) for \(domain.rawValue) domain.")
    }
}


struct AnalyzeArchitectureFromDocsIntent: AppIntent {
    static let title: LocalizedStringResource = "Analyze Architecture from Docs"
    static let description = IntentDescription("Parses technical documentation to identify architectural patterns and policies.")

    @Parameter(title: "Documentation Text")
    var docText: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Link to StudioViewModel.orchestrate with a specific "Analysis" mode
        return .result(dialog: "I've analyzed the documentation and identified several potential architectural policies.")
    }
}

struct NibblewayShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            // Use the new `policy` parameter directly and `domain` as an enum
            intent: ApplyPolicyIntent(),
            phrases: [
                "Apply \(\.$policy) policy in \(.applicationName)",
                "Review \(\.$domain) policies in \(.applicationName)"
            ],
            shortTitle: "Apply Nibbleway Policy",
            systemImageName: "shield.righthalf.filled"
        )
    }
}

