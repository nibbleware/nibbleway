import Foundation
import AppIntents
import SwiftUI

enum ViewMode: String, Codable, CaseIterable {
    case blueprint = "BLUEPRINT"
    case logicalFlow = "LOGICAL FLOW"
    case physicalFlow = "PHYSICAL FLOW"
}

enum C4Level: String, Codable {
    case person = "Person"
    case system = "Software System"
    case container = "Container"
    case component = "Component"
}

enum DiscoverySource: String, Codable {
    case git = "Git Repository"
    case infrastructure = "Cloud Infrastructure"
    case mcp = "MCP Protocol"
    case manual = "Architect Defined"
}

enum ArchitecturalState: String, Codable {
    case current = "Current"
    case target = "Target"
    case deprecated = "Deprecated"
}

struct ScmSource: Codable {
    let provider: String // "GitHub", "GitLab"
    let url: String
    let branch: String?
}

struct PublishTarget: Codable {
    let repoURL: String
    let branch: String
    let targetPath: String // e.g., "docs/architecture/"
}

struct PublishStatus: Codable {
    let lastPublished: Date?
    let commitHash: String?
    let url: String? // Link to PR or commit
}

struct ComplianceViolation: Codable {
    let ruleID: String
    let severity: String // "Low", "Medium", "High", "Critical"
    let message: String
}

struct ComplianceAudit: Codable {
    let timestamp: Date
    let status: String // "Pass", "Fail", "Warning"
    let violations: [ComplianceViolation]
}

struct DesignPattern: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let implementationGuidelines: String
}

struct PatternEvolution: Codable {
    let sourcePatternID: String?
    let targetPatternID: String
    let migrationStrategy: String
}

struct Milestone: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let targetDate: Date?
    var isCompleted: Bool = false
    var evolutionSteps: [String]? // Descriptions of specific changes in this moment
}

struct Moment: Codable, Identifiable {
    let id: String
    let name: String
    let snapshotDate: Date
    let blueprint: Blueprint // The state of architecture at this moment
}

struct Blueprint: Codable {
    let version: String
    let system: C4System
    var entities: [C4Entity]
    var relationships: [Relationship]
    var patterns: [DesignPattern]? // Catalog of patterns available/target
    var roadmap: [Milestone]?
    let policies: [Policy]?
}

struct SystemInfo: Codable {
    let name: String
    let description: String
}

struct C4Entity: Codable, Identifiable {
    let id: String
    let name: String
    let type: String // e.g., "Mobile App", "Database", "Architect"
    let technology: String
    var category: String?
    var vendor: String?
    var apiSpec: String?
    var level: C4Level // Mandated C4 Level
    var parentID: String? // Supporting C4 Hierarchy
    var execution: Execution?
    
    // Discovery Metadata
    var discoverySource: DiscoverySource = .manual
    var lastDiscovered: Date?
    var confidenceScore: Double = 1.0 // 0.0 to 1.0
    
    // Evolutionary State
    var state: ArchitecturalState = .current
    var milestoneID: String? // Which roadmap milestone introduces this
    var evolution: PatternEvolution? // If this entity is migrating patterns
    
    // UI Visual State
    var isActive: Bool = false
    
    // Agentic Orchestration (Xcode 26 Ready)
    var agentMetadata: AgentMetadata?

    enum CodingKeys: String, CodingKey {
        case id, name, type, technology, category, vendor, execution, agentMetadata, level
        case parentID = "parent_id"
        case apiSpec = "api_spec"
    }
    
    // Data Flow Awareness
    var dataClassification: String? // "Public", "Internal", "Secret"
    
    // Semantic Context
    var contextID: String? // Linking to a BoundedContext
    
    // Compliance & SCM Hook
    var scmSource: ScmSource?
    var lastAudit: ComplianceAudit?
}

struct BoundedContext: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    var domain: String? // e.g., "Sales", "Support", "Logistics"
}

struct GlossaryTerm: Codable, Identifiable {
    let id: String
    let term: String
    let definition: String
    let contextID: String? // Term can be global or context-specific
    var synonyms: [String]?

    enum CodingKeys: String, CodingKey {
        case id, term, definition, synonyms
        case contextID = "context_id"
    }
}

struct GlossaryRegistry: Codable {
    let version: String
    let contexts: [BoundedContext]
    let terms: [GlossaryTerm]
}

struct GuidingPrinciple: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let impact: String // e.g., "High", "Critical"
    var resources: [String]? // URLs or Doc paths
}

struct ArchitecturalPhilosophy: Codable {
    let missionStatement: String
    let principles: [GuidingPrinciple]
}

struct AgentMetadata: Codable {
    let model: String
    let temperature: Double?
    let capabilities: [String]?
    let orchestrationTasks: [OrchestrationTask]?
}

struct OrchestrationTask: Codable, Identifiable {
    let id: String
    let description: String
    var status: String // "pending", "delegated_to_xcode", "completed", "failed"
    let xcodeProject: String?
}

struct Execution: Codable {
    let type: String
    let command: String
    let args: [String]
    let env: [String: String]?
}

struct Relationship: Codable {
    let source: String
    let destination: String
    let description: String
    let protocolName: String
    
    // Data Lineage
    var schema: String?
    var transformation: String? // e.g., "Map user_id to account_id"
    var volumeRequirement: String? // e.g., "10k tps"

    enum CodingKeys: String, CodingKey {
        case source, destination, description
        case protocolName = "protocol"
    }
}

struct Policy: Codable {
    let id: String
    let format: String
    let source: String
}

// MARK: - Enterprise Registry

struct Registry: Codable {
    let version: String
    let items: [RegistryItem]
    
    enum CodingKeys: String, CodingKey {
        case version
        case items = "registry"
    }
}

struct RegistryItem: Codable, Identifiable {
    let id: String
    let name: String
    let category: String
    let vendor: String
    let type: String
    let technology: String
    let status: String
    let description: String
}

// MARK: - Architectural Discovery

struct ArchitecturalPolicy: Codable, Identifiable, AppEntity {
    typealias DefaultQuery = ArchitecturalPolicyQuery // Fixed: Point to ArchitecturalPolicyQuery
    
    let id: String
    let name: String
    let description: String
    let implementationGuidelines: String?

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Architectural Policy"
    static let defaultQuery = ArchitecturalPolicyQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(description)")
    }
}

struct PolicyContext: Codable {
    let domain: String
    let policies: [ArchitecturalPolicy]
}

// MARK: - Platform Development

struct PlatformStack: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let tools: [DevTool]
    let languages: [DevLanguage]
    let policies: [ArchitecturalPolicy]
}

struct DevTool: Codable {
    let name: String
    let versionRequirement: String?
}

struct DevLanguage: Codable {
    let name: String
    let versionRequirement: String?
}

struct Technology: Codable, Identifiable {
    let id: String
    let name: String
    let category: String // "Language", "Framework", "Database", "Cloud"
    let status: String // "Approved", "Evaluating", "Deprecated"
    let recommendedVersion: String?
    let description: String?
}

struct TechStack: Codable, Identifiable {
    let id: String
    let name: String
    let technologies: [Technology]
}

struct AgentRule: Codable, Identifiable {
    let id: String
    let category: String // "Coding Style", "Architecture", "Security"
    let instruction: String
}

struct AgentRuleSet: Codable, Identifiable {
    let id: String
    let name: String
    let context: String // "iOS", "Android", "Go-Backend"
    let rules: [AgentRule]
}

enum GuardrailDriftStatus: String, Codable {
    case inSync = "In Sync"
    case drifted = "Drifted"
    case missing = "Missing"
}

struct ProjectGuardrailStatus: Codable, Identifiable {
    let id: String // Project Name
    let ruleSetID: String
    let status: GuardrailDriftStatus
    let lastSync: Date
}

struct PortfolioAudit: Codable {
    let timestamp: Date
    let projectStatuses: [ProjectGuardrailStatus]
}

struct GovernanceRegistry: Codable {
    let version: String
    let philosophy: ArchitecturalPhilosophy?
    let techCatalog: [TechStack]?
    let agentRuleSets: [AgentRuleSet]?
    let policies: [ArchitecturalPolicy]
    let platforms: [PlatformStackDefinition]
    let flows: [DataFlow]?
}

struct DataFlow: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let type: ViewMode // .logicalFlow or .physicalFlow
    let steps: [FlowStep]
}

struct FlowStep: Codable, Identifiable {
    let id: String
    let sequence: Int
    let source: String // C4 Entity ID
    let destination: String // C4 Entity ID
    let operation: String // e.g., "Authorize", "Debit", "Log"
    let data: String // Business object or Technical payload
}

struct PlatformStackDefinition: Codable, Identifiable, AppEntity {
    typealias DefaultQuery = PlatformStackQuery // Fixed: Add DefaultQuery typealias
    
    let id: String
    let name: String
    let description: String
    let tools: [DevTool]
    let languages: [DevLanguage]
    let policies: [String] // IDs of policies

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Platform Stack"
    static let defaultQuery = PlatformStackQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(description)")
    }
}
// MARK: - AppEntityQuery Implementations

// Fixed: Define ArchitecturalPolicyQuery to conform to EntityQuery
struct ArchitecturalPolicyQuery: EntityQuery {
    typealias Entity = ArchitecturalPolicy

    func entities(for identifiers: [ArchitecturalPolicy.ID]) async throws -> [ArchitecturalPolicy] {
        return identifiers.map { id in
            ArchitecturalPolicy(id: id, name: "Policy \(id)", description: "This is a placeholder policy for ID: \(id)", implementationGuidelines: nil)
        }
    }
    
    func suggestedEntities() async throws -> [ArchitecturalPolicy] {
        return []
    }
}

// Fixed: Define PlatformStackQuery to conform to EntityQuery
struct PlatformStackQuery: EntityQuery {
    typealias Entity = PlatformStackDefinition

    func entities(for identifiers: [PlatformStackDefinition.ID]) async throws -> [PlatformStackDefinition] {
        return identifiers.map { id in
            PlatformStackDefinition(id: id, name: "Stack \(id)", description: "This is a placeholder stack for ID: \(id)", tools: [], languages: [], policies: [])
        }
    }
    
    func suggestedEntities() async throws -> [PlatformStackDefinition] {
        return []
    }
}

