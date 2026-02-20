import Foundation
import MCP
import System

@MainActor
class MCPManager: ObservableObject {
    @Published var isConnected = false
    @Published var isXcodeConnected = false
    @Published var discoveredTools: [Tool] = []
    
    private var client: Client?
    private var xcodeClient: Client?
    
    private var localProcess: Process?
    private var xcodeProcess: Process?
    
    func connectToLocalServer(command: String, args: [String]) async {
        let client = Client(
            name: "NibblewayStudio",
            version: "1.0.0"
        )
        
        do {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [command] + args
            
            let stdinPipe = Pipe()
            let stdoutPipe = Pipe()
            
            process.standardInput = stdinPipe
            process.standardOutput = stdoutPipe
            
            try process.run()
            self.localProcess = process
            
            let transport = StdioTransport(
                input: FileDescriptor(rawValue: stdoutPipe.fileHandleForReading.fileDescriptor),
                output: FileDescriptor(rawValue: stdinPipe.fileHandleForWriting.fileDescriptor)
            )
            
            try await client.connect(transport: transport)
            
            let result = try await client.listTools()
            self.discoveredTools = result.tools
            self.client = client
            self.isConnected = true
        } catch {
            print("Failed to connect to MCP server: \(error)")
        }
    }
    
    func connectToXcode() async {
        let client = Client(
            name: "NibblewayStudio",
            version: "1.0.0"
        )
        
        do {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["xcrun", "mcpbridge"]
            
            let stdinPipe = Pipe()
            let stdoutPipe = Pipe()
            
            process.standardInput = stdinPipe
            process.standardOutput = stdoutPipe
            
            try process.run()
            self.xcodeProcess = process
            
            let transport = StdioTransport(
                input: FileDescriptor(rawValue: stdoutPipe.fileHandleForReading.fileDescriptor),
                output: FileDescriptor(rawValue: stdinPipe.fileHandleForWriting.fileDescriptor)
            )
            
            try await client.connect(transport: transport)
            
            let result = try await client.listTools()
            self.discoveredTools.append(contentsOf: result.tools)
            self.xcodeClient = client
            self.isXcodeConnected = true
        } catch {
            print("Failed to connect to Xcode MCP bridge: \(error)")
        }
    }
    
    func delegateToXcode(task: OrchestrationTask) async {
        guard let client = xcodeClient else {
            print("Xcode MCP not connected")
            return
        }
        
        print("Delegating task to Xcode Agent: \(task.description)")
        
        do {
            if task.description.lowercased().contains("build") {
                _ = try await client.callTool(name: "BuildProject", arguments: [:])
            } else if task.description.lowercased().contains("test") {
                _ = try await client.callTool(name: "RunAllTests", arguments: [:])
            } else {
                _ = try await client.callTool(name: "GetBuildLog", arguments: [:])
            }
        } catch {
            print("Error executing Xcode tool: \(error)")
        }
    }
}

// Extension to help with Tool identification
extension Tool: @retroactive Identifiable {
    public var id: String { name }
}
