import Foundation
import Yams
import SwiftUI

@MainActor
class StudioViewModel: ObservableObject {
    @Published var blueprintYAML: String = ""
    @Published var blueprint: Blueprint?
    @Published var parseError: String?
    
    @Published var mcpManager = MCPManager()
    @Published var pklBridge = PklBridge()
    @Published var registry: Registry?
    @Published var governance: GovernanceRegistry?
    @Published var pulseEffect = false
    @Published var viewMode: ViewMode = .blueprint
    @Published var evolutionTarget: ArchitecturalState = .current
    
    // Discovery Feed
    @Published var discoveredEntities: [C4Entity] = []
    @Published var isDiscovering = false
    
    // Portfolio Governance
    @Published var portfolioAudit: PortfolioAudit?
    
    // Semantic Glossary
    @Published var glossary: GlossaryRegistry?

    private var architectContextServer: ArchitectContextServer?
    private var timer: Timer?

    init() {
        loadBlueprintFromFile()
        loadRegistry()
        loadGovernance()
        loadGlossary()
        pklBridge.loadPolicy(from: "Safety.pkl")
        
        self.architectContextServer = ArchitectContextServer(viewModel: self)
        Task {
            await architectContextServer?.start()
        }
        
        // Drive pulse for simple UI elements
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                withAnimation {
                    self.pulseEffect.toggle()
                }
            }
        }
    }

    func loadBlueprintFromFile() {
        // Try to find blueprint_schema.yaml in the parent directory
        // In a typical macOS app bundle, we'd need to go up several levels or use a file picker.
        // For development/debugging, we'll try a relative path from the CWD if possible, 
        // but since this is a compiled app, let's provide a way to load it or a fallback.
        
        let pathsToTry = [
            "../blueprint_schema.yaml",
            "blueprint_schema.yaml",
            "/Users/rickhohler/CODE/GITHUB/Nibbleware/nibbleway/blueprint_schema.yaml"
        ]
        
        for path in pathsToTry {
            if let content = try? String(contentsOfFile: path, encoding: .utf8) {
                self.blueprintYAML = content
                parseBlueprint()
                return
            }
        }
        
        // Fallback to sample if not found
        self.blueprintYAML = """
version: "1.0"
system:
  name: "Fallback System"
  description: "Could not find blueprint_schema.yaml"
entities:
  - id: "error"
    name: "File Not Found"
    level: "Container"
    type: "Agent"
    technology: "None"
"""
        parseBlueprint()
    }

    func parseBlueprint() {
        do {
            let decoder = YAMLDecoder()
            self.blueprint = try decoder.decode(Blueprint.self, from: blueprintYAML)
            self.parseError = nil
        } catch {
            self.parseError = error.localizedDescription
            print("Parse Error: \(error)")
        }
    }

    func updateYAML(_ newYAML: String) {
        let scrubbed = pklBridge.scrub(newYAML)
        self.blueprintYAML = scrubbed
        parseBlueprint()
    }
    
    func connectTools() {
        Task {
            // Placeholder for connecting to a local server based on C4 entities
            if let server = blueprint?.entities.first(where: { $0.execution != nil }) {
                await mcpManager.connectToLocalServer(
                    command: server.execution?.command ?? "",
                    args: server.execution?.args ?? []
                )
            }
            
            // Auto-connect to Xcode if it's running
            await mcpManager.connectToXcode()
        }
    }
    
    func delegateTask(_ task: OrchestrationTask) {
        Task {
            await mcpManager.delegateToXcode(task: task)
        }
    }
    
    func loadRegistry() {
        let pathsToTry = [
            "../enterprise_registry.yaml",
            "enterprise_registry.yaml",
            "/Users/rickhohler/CODE/GITHUB/Nibbleware/nibbleway/enterprise_registry.yaml"
        ]
        
        for path in pathsToTry {
            if let content = try? String(contentsOfFile: path, encoding: .utf8) {
                do {
                    let decoder = YAMLDecoder()
                    self.registry = try decoder.decode(Registry.self, from: content)
                    print("Registry loaded: \(registry?.items.count ?? 0) items")
                    return
                } catch {
                    print("Error decoding registry: \(error)")
                }
            }
        }
    }

    func loadGovernance() {
        let pathsToTry = [
            "../governance.yaml",
            "governance.yaml",
            "/Users/rickhohler/CODE/GITHUB/Nibbleware/nibbleway/governance.yaml"
        ]
        
        for path in pathsToTry {
            if let content = try? String(contentsOfFile: path, encoding: .utf8) {
                do {
                    let decoder = YAMLDecoder()
                    self.governance = try decoder.decode(GovernanceRegistry.self, from: content)
                    print("Governance loaded: \(governance?.policies.count ?? 0) policies, \(governance?.platforms.count ?? 0) platforms")
                    return
                } catch {
                    print("Error decoding governance: \(error)")
                }
            }
        }
    }

    func loadGlossary() {
        let pathsToTry = [
            "../glossary.yaml",
            "glossary.yaml",
            "/Users/rickhohler/CODE/GITHUB/Nibbleware/nibbleway/glossary.yaml"
        ]
        
        for path in pathsToTry {
            if let content = try? String(contentsOfFile: path, encoding: .utf8) {
                do {
                    let decoder = YAMLDecoder()
                    self.glossary = try decoder.decode(GlossaryRegistry.self, from: content)
                    print("Glossary loaded: \(glossary?.terms.count ?? 0) terms across \(glossary?.contexts.count ?? 0) contexts")
                    return
                } catch {
                    print("Error decoding glossary: \(error)")
                }
            }
        }
    }

    func orchestrate(command: String) {
        let cmd = command.lowercased()
        
        if cmd.contains("discover") || cmd.contains("scan") {
            triggerDiscovery(depth: cmd.contains("deep") ? 2 : 1)
            return
        }
        print("Architect Directive Received: \(cmd)")
        
        // Handle view mode switching via prompt
        if cmd.contains("logical view") || cmd.contains("logical flow") {
            withAnimation { self.viewMode = .logicalFlow }
        } else if cmd.contains("physical view") || cmd.contains("physical flow") {
            withAnimation { self.viewMode = .physicalFlow }
        } else if cmd.contains("blueprint") {
            withAnimation { self.viewMode = .blueprint }
        }
        
        // Push a visual update to represent the "thinking" phase
        withAnimation {
            self.pulseEffect = true
        }
        
        Task {
            try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
            await MainActor.run {
                withAnimation {
                    self.pulseEffect = false
                    // Here we would apply the resulting changes from the AI reasoning
                }
            }
        }
    }

    func triggerDiscovery(depth: Int) {
        guard !isDiscovering else { return }
        
        isDiscovering = true
        withAnimation { self.pulseEffect = true }
        
        Task {
            // Simulate discovery delay
            try? await Task.sleep(nanoseconds: 3 * 1_000_000_000)
            
            await MainActor.run {
                // Mock discovery results
                let mockEntity = C4Entity(
                    id: "discovered-auth-svc",
                    name: "Auth Microservice",
                    type: "Service",
                    technology: "Go / gRPC",
                    level: .container,
                    discoverySource: .mcp,
                    confidenceScore: 0.85
                )
                
                withAnimation {
                    self.discoveredEntities.append(mockEntity)
                    self.isDiscovering = false
                    self.pulseEffect = false
                }
                
                print("Discovery complete: Found \(mockEntity.name)")
            }
        }
    }
    
    func lookupGlossary(term: String, contextID: String?) -> String {
        guard let glossary = glossary else { return "Glossary not loaded." }
        
        let terms = glossary.terms.filter { $0.term.lowercased() == term.lowercased() }
        
        if terms.isEmpty {
            return "Term '\(term)' not found in enterprise glossary."
        }
        
        if let contextID = contextID {
            if let exactMatch = terms.first(where: { $0.contextID == contextID }) {
                return "Definition (\(contextID)): \(exactMatch.definition)"
            }
        }
        
        let response = terms.map { match in
            let ctx = match.contextID ?? "Global"
            return "[\(ctx)] \(match.definition)"
        }.joined(separator: "\n")
        
        return "Found \(terms.count) definitions for '\(term)':\n\(response)"
    }
    
    func generateMermaidC4() -> String {
        guard let blueprint = blueprint else { return "" }
        
        var mermaid = "```mermaid\nC4Context\n"
        mermaid += "  title \(blueprint.system.name)\n"
        
        for entity in blueprint.entities {
            let label = entity.name
            let tech = entity.technology
            switch entity.level {
            case .person:
                mermaid += "  Person(\(entity.id), \"\(label)\", \"\(entity.type)\")\n"
            case .system:
                mermaid += "  System(\(entity.id), \"\(label)\", \"\(entity.type)\", \"\(tech)\")\n"
            case .container:
                mermaid += "  Container(\(entity.id), \"\(label)\", \"\(entity.type)\", \"\(tech)\")\n"
            case .component:
                mermaid += "  Component(\(entity.id), \"\(label)\", \"\(entity.type)\", \"\(tech)\")\n"
            }
        }
        
        for rel in blueprint.relationships {
            mermaid += "  Rel(\(rel.source), \(rel.destination), \"\(rel.description)\", \"\(rel.protocolName)\")\n"
        }
        
        mermaid += "```"
        return mermaid
    }
    
    func publishArchitecture() {
        let docs = generateMermaidC4()
        print("Publishing Architectural Documentation to Governance Repo...")
        print("Generated Documentation:\n\(docs)")
        
        // Simulating Git push
        Task {
            try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
            await MainActor.run {
                print("Architecture successfully published to Git.")
            }
        }
    }
    
    func exportRules(for ruleSet: AgentRuleSet) {
        let content = ruleSet.rules.map { "# [\($0.category)]\n\($0.instruction)" }.joined(separator: "\n\n")
        let filename = ".\(ruleSet.context.lowercased())-agentrules.md"
        print("Exporting Rule Set to \(filename)...")
        print("Content:\n\(content)")
        // In a real app, this would show a file save panel
    }
    
    func auditPortfolio() {
        print("Auditing Portfolio Agent Guardrails...")
        // Simulated audit results
        let mockStatuses = [
            ProjectGuardrailStatus(id: "Nibbleway-App", ruleSetID: "ios-agent-rules", status: .inSync, lastSync: Date()),
            ProjectGuardrailStatus(id: "Account-Service", ruleSetID: "go-agent-rules", status: .drifted, lastSync: Date().addingTimeInterval(-86400 * 5)),
            ProjectGuardrailStatus(id: "Auth-Bridge", ruleSetID: "go-agent-rules", status: .missing, lastSync: Date().addingTimeInterval(-86400 * 30))
        ]
        
        withAnimation {
            self.portfolioAudit = PortfolioAudit(timestamp: Date(), projectStatuses: mockStatuses)
        }
    }
    
    func syncGuardrails(for projectID: String) {
        print("Syncing guardrails for \(projectID)...")
        // Simulate Git PR creation
        Task {
            try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
            await MainActor.run {
                if let index = portfolioAudit?.projectStatuses.firstIndex(where: { $0.id == projectID }) {
                    var statuses = portfolioAudit?.projectStatuses ?? []
                    statuses[index] = ProjectGuardrailStatus(id: projectID, ruleSetID: statuses[index].ruleSetID, status: .inSync, lastSync: Date())
                    self.portfolioAudit = PortfolioAudit(timestamp: Date(), projectStatuses: statuses)
                    print("Successfully synced \(projectID). PR created.")
                }
            }
        }
    }
}
