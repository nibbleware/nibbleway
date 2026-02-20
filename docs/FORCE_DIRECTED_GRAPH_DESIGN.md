# Force-Directed Graph: Design & Implementation

This guide explains how to implement the **Force-Directed Graph Simulator** on macOS using SwiftUI and the `Canvas` API.

---

## 1. The Physics Theory
A Force-Directed Graph treats nodes as physical objects and edges as springs. The system iterates until it reaches a "stable state" (equilibrium).

### The Math:
*   **Coulomb's Law (Repulsion)**: $F = k_r / d^2$. Nodes push away from each other.
*   **Hooke's Law (Attraction)**: $F = k_s * (d - L)$. Linked nodes pull toward each other to reach distance $L$.
*   **Damping**: $V = V * 0.9$. Prevents the system from oscillating indefinitely.

---

## 2. SwiftUI Implementation Pattern

### The Simulator (`GraphSimulator.swift`)
The simulator should run on the `@MainActor` or a background `Task`. It maintains a dictionary of node positions and velocities.

### The View Loop:
Use a `TimelineView` to create the update loop:

```swift
TimelineView(.periodic(from: .now, by: 1.0/60.0)) { timeline in
    Canvas { context, size in
        // 1. Tell the simulator to step its physics
        simulator.step()
        
        // 2. Map simulator coordinates to screen coordinates
        // 3. Draw nodes and relationships
    }
}
```

---

## 3. Performance Considerations
*   **O(N^2) Repulsion**: With 100+ nodes, repulsion becomes expensive. In a production tool like Nibbleway, you eventually move this to a **Barnes-Hut** tree search or a **Metal Compute Shader**.
*   **Off-Main-Thread Physics**: For the smoothest UI, the physics calculation (`step()`) should happen on a background thread, with the results being animated in the `Canvas`.

---

## 4. Key Learning Goals:
1.  Understand how to map **Abstract Models** (Agents/Vendors) to **Physical Coordinates**.
2.  Learn the `GraphicsContext` API in SwiftUI for high-performance drawing.
3.  Manage **State Synchronization** between the YAML editor and the Physics Engine.
