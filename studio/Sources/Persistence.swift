import Foundation
import SwiftData

@Model
class ExecutionRecord {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var agentId: String
    var agentName: String
    var prompt: String
    var response: String
    var toolCalls: [String]
    
    init(agentId: String, agentName: String, prompt: String, response: String, toolCalls: [String] = []) {
        self.id = UUID()
        self.timestamp = Date()
        self.agentId = agentId
        self.agentName = agentName
        self.prompt = prompt
        self.response = response
        self.toolCalls = toolCalls
    }
}
