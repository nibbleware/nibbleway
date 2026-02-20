import Foundation
import SwiftUI

/// A physics node in the force-directed graph.
struct GraphNode: Identifiable {
    let id: String
    var position: CGPoint
    var velocity: CGPoint = .zero
    var force: CGPoint = .zero
}

/// A physics spring (link) between nodes.
struct GraphLink {
    let sourceId: String
    let targetId: String
}

/// A physics simulator that calculates node positions for force-directed layouts.
@MainActor
final class GraphSimulator: ObservableObject {
    @Published private(set) var nodesByIdentifier: [String: GraphNode] = [:]
    private var relationships: [GraphLink] = []
    
    // Configuration constants
    private let optimalDistance: CGFloat = 100.0
    private let repulsionForce: CGFloat = 5000.0
    private let springStiffness: CGFloat = 0.05
    private let frictionDamping: CGFloat = 0.85
    
    /// Initializes the simulator with nodes and links derived from a blueprint.
    func configure(using blueprint: Blueprint) {
        var initializedNodes: [String: GraphNode] = [:]
        for entity in blueprint.entities {
            let initialPosition = CGPoint(
                x: CGFloat.random(in: -100...100),
                y: CGFloat.random(in: -100...100)
            )
            initializedNodes[entity.id] = GraphNode(id: entity.id, position: initialPosition)
        }
        self.nodesByIdentifier = initializedNodes
        self.relationships = blueprint.relationships.map { GraphLink(sourceId: $0.source, targetId: $0.destination) }
    }
    
    /// Executes a single integration step of the physics simulation.
    func updateSimulation() {
        // 1. Reset accumulated forces
        for identifier in nodesByIdentifier.keys {
            nodesByIdentifier[identifier]?.force = .zero
        }
        
        let identifiers = Array(nodesByIdentifier.keys)
        
        // 2. Calculate Repulsion (Coulomb's Law)
        for i in 0..<identifiers.count {
            for j in (i+1)..<identifiers.count {
                let idA = identifiers[i]
                let idB = identifiers[j]
                guard let nodeA = nodesByIdentifier[idA], let nodeB = nodesByIdentifier[idB] else { continue }
                
                let deltaX = nodeA.position.x - nodeB.position.x
                let deltaY = nodeA.position.y - nodeB.position.y
                let distanceSquared = deltaX * deltaX + deltaY * deltaY + 0.01
                let distance = sqrt(distanceSquared)
                
                let forceMagnitude = repulsionForce / distanceSquared
                let forceX = forceMagnitude * (deltaX / distance)
                let forceY = forceMagnitude * (deltaY / distance)
                
                nodesByIdentifier[idA]?.force.x += forceX
                nodesByIdentifier[idA]?.force.y += forceY
                nodesByIdentifier[idB]?.force.x -= forceX
                nodesByIdentifier[idB]?.force.y -= forceY
            }
        }
        
        // 3. Calculate Attraction (Hooke's Law)
        for link in relationships {
            guard let nodeA = nodesByIdentifier[link.sourceId], let nodeB = nodesByIdentifier[link.targetId] else { continue }
            
            let deltaX = nodeB.position.x - nodeA.position.x
            let deltaY = nodeB.position.y - nodeA.position.y
            let distance = sqrt(deltaX * deltaX + deltaY * deltaY) + 0.01
            
            let forceMagnitude = springStiffness * (distance - optimalDistance)
            let forceX = forceMagnitude * (deltaX / distance)
            let forceY = forceMagnitude * (deltaY / distance)
            
            nodesByIdentifier[link.sourceId]?.force.x += forceX
            nodesByIdentifier[link.sourceId]?.force.y += forceY
            nodesByIdentifier[link.targetId]?.force.x -= forceX
            nodesByIdentifier[link.targetId]?.force.y -= forceY
        }
        
        // 4. Integrate forces into velocity and position
        for identifier in nodesByIdentifier.keys {
            guard var node = nodesByIdentifier[identifier] else { continue }
            
            node.velocity.x = (node.velocity.x + node.force.x) * frictionDamping
            node.velocity.y = (node.velocity.y + node.force.y) * frictionDamping
            
            node.position.x += node.velocity.x
            node.position.y += node.velocity.y
            
            nodesByIdentifier[identifier] = node
        }
    }
}
