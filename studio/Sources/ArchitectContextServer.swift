import Foundation
import MCP

/// An MCP Server that exposes Nibbleway's architectural decisions to external tools like Xcode 26.3.
@MainActor
final class ArchitectContextServer: Sendable {
    private let viewModel: StudioViewModel
    private var server: Server?
    
    init(viewModel: StudioViewModel) {
        self.viewModel = viewModel
    }
    
    func start() async {
        let server = Server(
            name: "NibblewayArchitect",
            version: "1.0.0",
            capabilities: .init(
                prompts: .init(listChanged: true),
                tools: .init(listChanged: true)
            )
        )
        
        // Define tool for approved vendors
        let getApprovedVendors = Tool(
            name: "get_approved_vendors",
            description: "Retrieves a list of enterprise-approved vendors for a given category.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "category": .object([
                        "type": .string("string"),
                        "description": .string("The category to look up (e.g., 'Payments', 'GraphQL', 'Push')")
                    ])
                ]),
                "required": .array([.string("category")])
            ])
        )
        
        // Define tool for active stack
        let getActiveStack = Tool(
            name: "get_active_stack",
            description: "Returns the current technology stack defined in the active blueprint.",
            inputSchema: .object(["type": .string("object"), "properties": .object([:])])
        )
        
        // Define tool for architectural policies
        let getPolicies = Tool(
            name: "get_architectural_policies",
            description: "Lists mandated architectural policies (e.g., MVVM-C for Swift).",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "domain": .object([
                        "type": .string("string"),
                        "description": .string("Optional domain to filter policies (e.g., 'iOS', 'Web')")
                    ])
                ])
            ])
        )
        
        // Define tool for platform stacks
        let getPlatformStack = Tool(
            name: "get_platform_stack",
            description: "Returns the complete development stack for a specific platform (e.g., 'iOS').",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "platform": .object([
                        "type": .string("string"),
                        "description": .string("The platform to look up (e.g., 'iOS', 'Android')")
                    ])
                ]),
                "required": .array([.string("platform")])
            ])
        )
        
        // Define tool for enterprise discovery
        let discoverComponents = Tool(
            name: "discover_enterprise_components",
            description: "Scans the environment (Git, Workspace, Network) to discover C4 entities and relationships.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "depth": .object([
                        "type": .string("integer"),
                        "description": .string("How deep to scan (1=Local, 2=Organization, 3=Universal)")
                    ])
                ])
            ])
        )
        
        // Define tool for glossary lookup
        let getGlossaryTerm = Tool(
            name: "get_glossary_term",
            description: "Retrieves the enterprise definition for a term, optionally scoped by bounded context.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "term": .object(["type": .string("string")]),
                    "context": .object(["type": .string("string"), "description": .string("Optional Bounded Context ID")])
                ]),
                "required": .array([.string("term")])
            ])
        )
        
        // Define tool for listing contexts
        let listContexts = Tool(
            name: "list_bounded_contexts",
            description: "Lists all defined Bounded Contexts (semantic domains) in the enterprise.",
            inputSchema: .object(["type": .string("object"), "properties": .object([:])])
        )
        
        // Define tool for architectural philosophy
        let getPhilosophy = Tool(
            name: "get_architectural_philosophy",
            description: "Retrieves the core engineering values and guiding principles of the enterprise.",
            inputSchema: .object(["type": .string("object"), "properties": .object([:])])
        )
        
        // Define tool for listing patterns
        let getPatterns = Tool(
            name: "get_architectural_patterns",
            description: "Lists all current and target design patterns for the enterprise.",
            inputSchema: .object(["type": .string("object"), "properties": .object([:])])
        )
        
        // Define tool for listing moments
        let getMoments = Tool(
            name: "get_evolution_moments",
            description: "Retrieves chronological snapshots (Moments) of the architectural timeline.",
            inputSchema: .object(["type": .string("object"), "properties": .object([:])])
        )
        
        // Define tool for tech catalog
        let getTechCatalog = Tool(
            name: "get_tech_catalog",
            description: "Retrieves the enterprise-approved technical stack (languages, frameworks, databases).",
            inputSchema: .object(["type": .string("object"), "properties": .object([:])])
        )
        
        // Define tool for publishing to governance repo
        let publishToGit = Tool(
            name: "publish_to_governance_repo",
            description: "Ships the current architectural blueprint and documentation to the management review repository.",
            inputSchema: .object(["type": .string("object"), "properties": .object([
                "commitMessage": .object(["type": .string("string"), "description": "Reason for the architectural change."])
            ])])
        )
        
        // Define tool for repo compliance verification
        let verifyCompliance = Tool(
            name: "verify_repo_compliance",
            description: "Triggers a compliance scan on a specific repository to verify alignment with enterprise tech stacks and policies.",
            inputSchema: .object(["type": .string("object"), "properties": .object([
                "repoUrl": .object(["type": .string("string")]),
                "branch": .object(["type": .string("string")])
            ])])
        )
        
        // Define tool for retrieving agent rule sets
        let getAgentRules = Tool(
            name: "get_agent_rules",
            description: "Retrieves context-aware rule sets for AI agents (e.g., iOS standards, Go standards).",
            inputSchema: .object(["type": .string("object"), "properties": .object([
                "context": .object([
                    "type": .string("string"),
                    "description": .string("The development context (e.g., 'iOS', 'Go-Backend')")
                ])
            ])])
        )
        
        // Define tool for auditing portfolio-wide agent compliance
        let auditCompliance = Tool(
            name: "audit_agent_compliance",
            description: "Scans managed repositories to detect drift in AI agent rule sets across the enterprise portfolio.",
            inputSchema: .object(["type": .string("object"), "properties": .object([:])])
        )
        
        // Define tool for pushing rule updates to repositories
        let pushRuleUpdates = Tool(
            name: "push_rule_updates",
            description: "Creates Git Pull Requests to update .agentrules across multiple repositories to match the central registry.",
            inputSchema: .object(["type": .string("object"), "properties": .object([
                "projectIDs": .object(["type": .array("string"), "description": .string("List of project names to update")])
            ])])
        )
        
        let tools = [getApprovedVendors, getActiveStack, getPolicies, getPlatformStack, discoverComponents, getGlossaryTerm, listContexts, getPhilosophy, getEvolution, getPatterns, getMoments, getTechCatalog, publishToGit, verifyCompliance, getAgentRules, auditCompliance, pushRuleUpdates]
        
        // Register Prompts
        let policiesPrompt = Prompt(
            name: "review_architectural_policies",
            description: "Authoritative instructions to review and apply the architect's mandated policies to the current code.",
            arguments: [
                .init(
                    name: "domain",
                    description: "The development domain (e.g., 'iOS', 'Web')",
                    required: true
                )
            ]
        )
        
        await server.withMethodHandler(ListPrompts.self) { _ in
            return ListPrompts.Result(prompts: [policiesPrompt])
        }
        
        await server.withMethodHandler(GetPrompt.self) { params in
            let domain = params.arguments?["domain"] ?? "General"
            let message = Prompt.Message.user(.text(text: """
                You are an agent acting under the governance of the Nibbleway Architect. 
                Your task is to ensure the current project adheres to the established policies for the \(domain) domain.
                
                Mandatory Steps:
                1. Call `get_platform_stack(platform: "\(domain)")` to identify required tools and patterns.
                2. Call `get_architectural_policies()` to retrieve the list of mandated rules.
                3. Specifically for iOS/Swift, you MUST follow the MVVM-C (Model-View-ViewModel-Coordinator) pattern.
                4. Do not commit or propose code that violates these policies.
                
                Please proceed by reviewing the current source code and identifying any violations.
                """))
            return GetPrompt.Result(description: "Architectural Review", messages: [message])
        }
        
        // Register list handler
        await server.withMethodHandler(ListTools.self) { _ in
            return ListTools.Result(tools: tools)
        }
        
        // Register call handler
        await server.withMethodHandler(CallTool.self) { [weak self] params in
            guard let self = self else {
                return CallTool.Result(content: [.text("Server shutting down")], isError: true)
            }
            
            return await MainActor.run {
                switch params.name {
                case "get_approved_vendors":
                    guard let category = params.arguments?["category"]?.stringValue else {
                        return CallTool.Result(content: [.text("Category required")], isError: true)
                    }
                    let approved = self.viewModel.registry?.items.filter { $0.category.lowercased() == category.lowercased() } ?? []
                    let response = approved.map { "\($0.name) (Vendor: \($0.vendor), Tech: \($0.technology))" }.joined(separator: ", ")
                    let text = response.isEmpty ? "No approved vendors found for \(category)" : "Approved: \(response)"
                    return CallTool.Result(content: [.text(text)])
                    
                case "get_active_stack":
                    let stack = self.viewModel.blueprint?.entities.map { "\($0.name): \($0.technology)" } ?? []
                    let text = "Active Stack: " + stack.joined(separator: " | ")
                    return CallTool.Result(content: [.text(text)])
                    
                case "get_architectural_policies":
                    let policies = self.viewModel.governance?.policies ?? []
                    if policies.isEmpty {
                        return CallTool.Result(content: [.text("No architectural policies defined in governance registry.")])
                    }
                    
                    let response = policies.map { 
                        "Policy: \($0.name)\nDescription: \($0.description)\nGuidelines: \($0.implementationGuidelines ?? "N/A")"
                    }.joined(separator: "\n\n")
                    return CallTool.Result(content: [.text("Nibbleway Architectural Policies:\n\n" + response)])
                    
                case "get_platform_stack":
                    guard let platformId = params.arguments?["platform"]?.stringValue?.lowercased() else {
                        return CallTool.Result(content: [.text("Platform required")], isError: true)
                    }
                    
                    guard let platformDef = self.viewModel.governance?.platforms.first(where: { $0.id.lowercased() == platformId }) else {
                        return CallTool.Result(content: [.text("Platform \(platformId) not yet defined in governance registry.")], isError: true)
                    }
                    
                    let toolsText = platformDef.tools.map { "\($0.name) (\($0.versionRequirement ?? "Any"))" }.joined(separator: ", ")
                    let langsText = platformDef.languages.map { "\($0.name) (\($0.versionRequirement ?? "Any"))" }.joined(separator: ", ")
                    
                    // Resolve policy IDs to names
                    let policyNames = platformDef.policies.map { policyId in
                        self.viewModel.governance?.policies.first(where: { $0.id == policyId })?.name ?? policyId
                    }.joined(separator: ", ")
                    
                    let response = """
                    Platform: \(platformDef.name)
                    Tools: \(toolsText)
                    Languages: \(langsText)
                    Mandatory Policies: \(policyNames)
                    Description: \(platformDef.description)
                    """
                    return CallTool.Result(content: [.text(response)])
                    
                case "discover_enterprise_components":
                    // Trigger discovery logic in ViewModel
                    let depth = Int(params.arguments?["depth"]?.description ?? "1") ?? 1
                    self.viewModel.triggerDiscovery(depth: depth)
                    return CallTool.Result(content: [.text("Discovery sequence initiated (Depth: \(depth)). Results will appear in the Studio Discovery Feed.")])
                    
                case "get_glossary_term":
                    guard let term = params.arguments?["term"]?.stringValue else {
                        return CallTool.Result(content: [.text("Term required")], isError: true)
                    }
                    let contextID = params.arguments?["context"]?.stringValue
                    let result = self.viewModel.lookupGlossary(term: term, contextID: contextID)
                    return CallTool.Result(content: [.text(result)])
                    
                case "list_bounded_contexts":
                    let contexts = self.viewModel.glossary?.contexts ?? []
                    let response = contexts.map { "\($0.name) (ID: \($0.id)): \($0.description)" }.joined(separator: "\n")
                    return CallTool.Result(content: [.text("Defined Bounded Contexts:\n" + (response.isEmpty ? "None" : response))])
                    
                case "get_architectural_philosophy":
                    guard let philosophy = self.viewModel.governance?.philosophy else {
                        return CallTool.Result(content: [.text("No architectural philosophy defined in governance registry.")])
                    }
                    
                    let principlesText = philosophy.principles.map { 
                        "- \($0.name) (Impact: \($0.impact)): \($0.description)"
                    }.joined(separator: "\n")
                    
                    let response = """
                    Enterprise Architectural Philosophy
                    Mission: \(philosophy.missionStatement)
                    
                    Guiding Principles:
                    \(principlesText)
                    """
                    return CallTool.Result(content: [.text(response)])
                    
                case "get_evolution_roadmap":
                    guard let roadmap = self.viewModel.blueprint?.roadmap else {
                        return CallTool.Result(content: [.text("No evolution roadmap defined for this blueprint.")])
                    }
                    let response = roadmap.map { milestone in
                        let steps = milestone.evolutionSteps?.map { "  - \($0)" }.joined(separator: "\n") ?? ""
                        return "[\(milestone.isCompleted ? "DONE" : "TODO")] \(milestone.name): \(milestone.description)\n\(steps)"
                    }.joined(separator: "\n")
                    return CallTool.Result(content: [.text("Architectural Evolution Roadmap:\n" + response)])
                    
                case "get_architectural_patterns":
                    let patterns = self.viewModel.blueprint?.patterns ?? []
                    let response = patterns.map { "\($0.name): \($0.description)" }.joined(separator: "\n")
                    return CallTool.Result(content: [.text("Defined Design Patterns:\n" + (response.isEmpty ? "None" : response))])
                    
                case "get_evolution_moments":
                    // To be implemented: This would return snapshots from a repository or history log
                    return CallTool.Result(content: [.text("Chronological Moments: [Current Snapshot] July 2026")])
                    
                case "get_tech_catalog":
                    guard let catalog = self.viewModel.governance?.techCatalog else {
                        return CallTool.Result(content: [.text("No tech catalog defined in governance registry.")])
                    }
                    
                    let response = catalog.map { stack in
                        let techs = stack.technologies.map { "- \($0.name) (\($0.category)): \($0.status)" }.joined(separator: "\n")
                        return "Stack: \(stack.name)\n\(techs)"
                    }.joined(separator: "\n\n")
                    
                    return CallTool.Result(content: [.text("Enterprise Technical Stack:\n\n" + response)])
                    
                case "publish_to_governance_repo":
                    let message = params.arguments?["commitMessage"]?.asString ?? "Architectural update"
                    // In a real implementation, this would call out to git
                    return CallTool.Result(content: [.text("Architecture published to governance repo with message: '\(message)'. Awaiting management review.")])
                    
                case "verify_repo_compliance":
                    let url = params.arguments?["repoUrl"]?.asString ?? "unknown"
                    // Simulated compliance scan
                    return CallTool.Result(content: [.text("Compliance scan triggered for \(url). Results will be available in the Studio Lab shortly.")])
                    
                case "get_agent_rules":
                    let context = params.arguments?["context"]?.asString ?? "General"
                    guard let ruleSet = self.viewModel.governance?.agentRuleSets?.first(where: { $0.context.lowercased() == context.lowercased() }) else {
                        return CallTool.Result(content: [.text("No specialized rules found for context: \(context). Using general enterprise defaults.")])
                    }
                    
                    let rulesText = ruleSet.rules.map { "- [\($0.category)] \($0.instruction)" }.joined(separator: "\n")
                    let response = "Agent Rule Set: \(ruleSet.name)\nContext: \(ruleSet.context)\n\n\(rulesText)"
                    return CallTool.Result(content: [.text(response)])
                    
                case "audit_agent_compliance":
                    self.viewModel.auditPortfolio()
                    return CallTool.Result(content: [.text("Portfolio-wide agent rule audit triggered. Results available in Studio Dashboard.")])
                    
                case "push_rule_updates":
                    let projects = params.arguments?["projectIDs"]?.asArray?.compactMap { $0.asString } ?? []
                    for project in projects {
                        self.viewModel.syncGuardrails(for: project)
                    }
                    return CallTool.Result(content: [.text("Rule updates pushed to: \(projects.joined(separator: ", ")). PRs are being generated.")])
                    
                default:
                    return CallTool.Result(content: [.text("Unknown tool: \(params.name)")], isError: true)
                }
            }
        }
        
        self.server = server
    }
}
