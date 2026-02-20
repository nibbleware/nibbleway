import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var viewModel = StudioViewModel()
    @State private var commandInput: String = ""
    @State private var isShowingHUD: Bool = false
    
    var body: some View {
        NavigationSplitView {
            sidebar
                .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))
        } content: {
            visualizerArea
                .background(Color.black.opacity(0.9))
        } detail: {
            inspectorArea
                .background(VisualEffectView(material: .windowBackground, blendingMode: .behindWindow))
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Components
    
    private var sidebar: some View {
        List {
            if let blueprint = viewModel.blueprint {
                Section("C4 Persons & Systems") {
                    ForEach(blueprint.entities.filter { 
                        ($0.level == .person || $0.level == .system) && 
                        ($0.state == viewModel.evolutionTarget || viewModel.evolutionTarget == .current)
                    }) { entity in
                        Label(entity.name, systemImage: entity.level == .person ? "person.fill" : "macmini.fill")
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                
                Section("Xcode 26.3 Integration") {
                    HStack {
                        Circle()
                            .fill(viewModel.mcpManager.isXcodeConnected ? Color.blue : Color.gray)
                            .frame(width: 8, height: 8)
                            .shadow(color: viewModel.mcpManager.isXcodeConnected ? .blue : .gray, radius: 4)
                        Text(viewModel.mcpManager.isXcodeConnected ? "XCODE ACTIVE" : "XCODE OFFLINE")
                            .font(.system(.caption, design: .monospaced))
                            .bold()
                        Spacer()
                    }
                    
                    let tasks = blueprint.entities.compactMap({ $0.agentMetadata?.orchestrationTasks }).flatMap({ $0 })
                    if !tasks.isEmpty {
                        ForEach(tasks) { task in
                            delegationRow(task)
                        }
                    }
                }
                
                Section("Discovered MCP Tools") {
                    ForEach(viewModel.mcpManager.discoveredTools) { tool in
                        Label(tool.name, systemImage: "hammer.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("C4 Containers & Components") {
                    ForEach(blueprint.entities.filter { 
                        ($0.level == .container || $0.level == .component) &&
                        ($0.state == viewModel.evolutionTarget || viewModel.evolutionTarget == .current)
                    }) { entity in
                        VStack(alignment: .leading) {
                            Label(entity.name, systemImage: entity.level == .container ? "box.truck.fill" : "cpu.fill")
                                .font(.subheadline)
                            if let technology = entity.technology as String? {
                                Text(technology.uppercased())
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                            if let vendor = entity.vendor {
                                Text("VNDR: \(vendor)")
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundStyle(.blue.opacity(0.8))
                            }
                        }
                        .opacity(entity.state == viewModel.evolutionTarget ? 1.0 : 0.4)
                        .padding(.vertical, 2)
                    }
                }
                
                if let registry = viewModel.registry {
                    Section("Enterprise Catalog") {
                        ForEach(registry.items) { item in
                            VStack(alignment: .leading) {
                                Label(item.name, systemImage: "checkmark.seal.fill")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                Text(item.category)
                                    .font(.system(size: 7, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                            .help(item.description)
                        }
                    }
                }

                if let governance = viewModel.governance {
                    Section("Governance & Policies") {
                        ForEach(governance.policies) { policy in
                            VStack(alignment: .leading) {
                                Label(policy.name, systemImage: "shield.righthalf.filled")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                                Text(policy.description)
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
                
                if !viewModel.discoveredEntities.isEmpty {
                    Section("Discovery Feed (\(viewModel.discoveredEntities.count))") {
                        ForEach(viewModel.discoveredEntities) { entity in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(entity.name)
                                        .font(.caption)
                                        .bold()
                                    Text("SRC: \(entity.discoverySource.rawValue) (\(Int(entity.confidenceScore * 100))%)")
                                        .font(.system(size: 7, design: .monospaced))
                                        .foregroundStyle(.orange)
                                }
                                Spacer()
                                Button(action: { viewModel.publishArchitecture() }) {
                    Label("PUBLISH", systemImage: "arrow.up.doc.fill")
                        .font(.system(size: 10, weight: .bold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(.blue)
                
                Button(action: { isShowingHUD.toggle() }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.green)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                Section("Compliance Lab") {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.green)
                        Text("Enterprise Sync: OK")
                            .font(.system(size: 9, design: .monospaced))
                        Spacer()
                    }
                    
                    Button("Trigger Full Audit") {
                        // Action
                    }
                    .font(.system(size: 10, weight: .bold))
                    .buttonStyle(.bordered)
                }
                
                if let ruleSets = viewModel.governance?.agentRuleSets {
                    Section("Agent Guardrails") {
                        ForEach(ruleSets) { ruleSet in
                            VStack(alignment: .leading) {
                                Text(ruleSet.name)
                                    .font(.system(size: 10, weight: .bold))
                                HStack {
                                    Text("\(ruleSet.rules.count) rules")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Button("Export") {
                                        viewModel.exportRules(for: ruleSet)
                                    }
                                    .font(.system(size: 9))
                                    .buttonStyle(.borderless)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                
                if let glossary = viewModel.glossary {
                    Section("Enterprise Glossary") {
                        ForEach(glossary.terms) { term in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(term.term)
                                        .font(.caption)
                                        .bold()
                                    if let contextID = term.contextID {
                                        Text(contextID.uppercased())
                                            .font(.system(size: 6, design: .monospaced))
                                            .padding(2)
                                            .background(.orange.opacity(0.2))
                                            .cornerRadius(2)
                                    }
                                }
                                Text(term.definition)
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("STUDIO")
    }
    
    private var statusRow: some View {
        HStack {
            Circle()
                .fill(viewModel.mcpManager.isConnected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
                .shadow(color: viewModel.mcpManager.isConnected ? .green : .red, radius: 4)
            Text(viewModel.mcpManager.isConnected ? "CONNECTED" : "OFFLINE")
                .font(.system(.caption, design: .monospaced))
                .bold()
            Spacer()
            if !viewModel.mcpManager.isConnected {
                Button("CONNECT") {
                    viewModel.connectTools()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
    
    private func delegationRow(_ task: OrchestrationTask) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(task.description)
                    .font(.caption)
                Text(task.status.uppercased())
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: { viewModel.delegateTask(task) }) {
                Image(systemName: "arrow.up.forward.square.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
    }

    private var visualizerArea: some View {
        ZStack(alignment: .topTrailing) {
            if let blueprint = viewModel.blueprint {
                TimelineView(.periodic(from: .now, by: 1.0/60.0)) { timeline in
                    Canvas { context, size in
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        let radius = min(size.width, size.height) / 3
                        let pulse = abs(sin(timeline.date.timeIntervalSinceReferenceDate * 2))
                        let time = timeline.date.timeIntervalSinceReferenceDate
                        
                        // Draw Flow Lines & Data Packets
                        let relationships = blueprint.relationships
                        for rel in relationships {
                            drawRelationship(rel, in: &context, center: center, radius: radius, blueprint: blueprint, time: time)
                        }
                        
                        // Draw Nodes
                        let visibleEntities = blueprint.entities.enumerated().filter { (idx, entity) in
                            entity.state == viewModel.evolutionTarget || viewModel.evolutionTarget == .current
                        }
                        
                        for (index, entity) in visibleEntities {
                            drawNode(entity, at: index, count: blueprint.entities.count, in: &context, center: center, radius: radius, pulse: pulse)
                        }
                    }
                }
            }
            
            VStack {
                Picker("View Mode", selection: $viewModel.viewMode) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(8)
                .shadow(radius: 5)
                
                Picker("Evolution", selection: $viewModel.evolutionTarget.animation()) {
                    Text("Current").tag(ArchitecturalState.current)
                    Text("Target").tag(ArchitecturalState.target)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                .padding(.horizontal)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
                .shadow(radius: 5)
                
                VStack(spacing: 4) {
                    Text("MOMENT TRAJECTORY")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Slider(value: $viewModel.currentMomentIndex, in: 0...1, step: 0.1)
                        .frame(width: 200)
                }
                .padding(8)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
                .shadow(radius: 5)
                
                Spacer()
            }
            .padding(.top, 40)
            
            if isShowingHUD {
                commandHUD
                    .transition(.move(edge: .top).combined(with: .opacity))
            } else {
                Button(action: { withAnimation(.spring()) { isShowingHUD = true } }) {
                    Label("ORCHESTRATE", systemImage: "command")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                }
                .padding()
                .buttonStyle(.plain)
            }
        }
    }
    
    private func drawRelationship(_ rel: Relationship, in context: inout GraphicsContext, center: CGPoint, radius: CGFloat, blueprint: Blueprint, time: Double) {
        guard let sourceIdx = blueprint.entities.firstIndex(where: { $0.id == rel.source }),
              let destIdx = blueprint.entities.firstIndex(where: { $0.id == rel.destination }) else { return }
        
        let sourceAngle = Double(sourceIdx) / Double(blueprint.entities.count) * 2 * .pi
        let destAngle = Double(destIdx) / Double(blueprint.entities.count) * 2 * .pi
        
        let start = CGPoint(x: center.x + CGFloat(cos(sourceAngle)) * radius, y: center.y + CGFloat(sin(sourceAngle)) * radius)
        let end = CGPoint(x: center.x + CGFloat(cos(destAngle)) * radius, y: center.y + CGFloat(sin(destAngle)) * radius)
        
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        
        context.stroke(path, with: .color(relationshipColor(rel)), style: StrokeStyle(lineWidth: viewModel.viewMode == .blueprint ? 1 : 2))
        
        // Data Packet Animation
        let packetPos = (time * 0.5).truncatingRemainder(dividingBy: 1.0)
        let packetX = start.x + (end.x - start.x) * CGFloat(packetPos)
        let packetY = start.y + (end.y - start.y) * CGFloat(packetPos)
        
        let packetColor = viewModel.viewMode == .logicalFlow ? Color.orange : Color.cyan
        context.fill(Path(ellipseIn: CGRect(x: packetX - 3, y: packetY - 3, width: 6, height: 6)), with: .color(packetColor))
        context.addFilter(.shadow(color: packetColor, radius: 3))
        
        // Label protocols in Physical View
        if viewModel.viewMode == .physicalFlow {
            context.draw(Text(rel.protocolName.uppercased())
                .font(.system(size: 6, design: .monospaced))
                .foregroundColor(.cyan), at: CGPoint(x: (start.x + end.x)/2, y: (start.y + end.y)/2 - 10))
        }
    }
    
    private func relationshipColor(_ rel: Relationship) -> Color {
        switch viewModel.viewMode {
        case .blueprint: return .blue.opacity(0.15)
        case .logicalFlow: return .orange.opacity(0.3)
        case .physicalFlow: return .cyan.opacity(0.3)
        }
    }
    
    private func drawNode(_ entity: C4Entity, at index: Int, count: Int, in context: inout GraphicsContext, center: CGPoint, radius: CGFloat, pulse: Double) {
        let angle = Double(index) / Double(count) * 2.0 * .pi
        let x = center.x + CGFloat(cos(angle)) * radius
        let y = center.y + CGFloat(sin(angle)) * radius
        let rect = CGRect(x: x - 45, y: y - 22, width: 90, height: 44)
        
        let baseColor: Color = {
            if entity.isActive { return .green }
            switch viewModel.viewMode {
            case .blueprint: return .blue
            case .logicalFlow: return .orange
            case .physicalFlow: return .cyan
            }
        }()
        
        // Node Border & Fill
        let borderPath = Path(roundedRect: rect, cornerRadius: 10)
        context.fill(borderPath, with: .color(Color(white: 0.1)))
        context.stroke(borderPath, with: .color(entity.isActive ? .green : baseColor.opacity(0.6)), lineWidth: 1.5)
        
        // Metadata in Physical Mode
        if viewModel.viewMode == .physicalFlow {
             context.draw(Text(entity.technology.replacingOccurrences(of: " ", with: "_").uppercased())
                .font(.system(size: 6, design: .monospaced))
                .foregroundColor(baseColor), at: CGPoint(x: x, y: y + 14))
        }
        
        // Text
        context.draw(Text(entity.name.uppercased())
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(.white), at: CGPoint(x: x, y: y))
    }
    
    private var commandHUD: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "command")
                    .foregroundColor(.blue)
                Text("ARCHITECT COMMAND HUD")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                Spacer()
                Button(action: { withAnimation { isShowingHUD = false } }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(10)
            .background(Color.black.opacity(0.3))
            
            TextEditor(text: $commandInput)
                .font(.system(.body, design: .monospaced))
                .frame(height: 80)
                .padding(8)
                .writingToolsBehavior(.complete)
                .scrollContentBackground(.hidden)
            
            HStack {
                Text("APPLE INTELLIGENCE ACTIVE")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: {
                    viewModel.orchestrate(command: commandInput)
                    commandInput = ""
                    withAnimation { isShowingHUD = false }
                }) {
                    Text("EXECUTE INTENT")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }
            .padding(8)
        }
        .frame(width: 400)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.3), lineWidth: 1))
        .padding()
        .shadow(radius: 20)
    }
    
    private var inspectorArea: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("BLUEPRINT ARCHITECT")
                    .font(.system(.headline, design: .monospaced))
                    .bold()
                Spacer()
                if let error = viewModel.parseError {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                        .help(error)
                }
            }
            .padding()
            
            TextEditor(text: Binding(
                get: { viewModel.blueprintYAML },
                set: { viewModel.updateYAML($0) }
            ))
            .font(.system(.body, design: .monospaced))
            .writingToolsBehavior(.complete)
            .scrollContentBackground(.hidden)
            .padding(.horizontal)
        }
    }
}

// MARK: - Helpers

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

#Preview {
    ContentView()
}
