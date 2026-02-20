# Swift API Design Guidelines: Nibbleway Standard

To build an "Architect-Pro" tool, your code must feel like it was written by Apple's own engineers. We strictly follow the [Official Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/).

---

## 1. Fundamentals: Clarity at Point of Use
The most important rule in Swift: **Clarity is more important than brevity.**

### Names Should Self-Document:
| ❌ Bad (Vague) | ✅ Good (Swift Idiom) |
| :--- | :--- |
| `func move()` | `func move(to destination: CGPoint)` |
| `var nodes: [Node]` | `var graphNodes: [GraphNode]` |
| `func fetch()` | `func fetchBlueprint()` |

### Omit Needless Words:
Don't repeat type information in a name if it's already clear from the context.
*   **Bad**: `blueprint.blueprintName`
*   **Good**: `blueprint.name`

---

## 2. Naming Conventions

### Variables and Functions
*   **CamelCase**: Use `lowerCamelCase` for variables and functions.
*   **Roles vs. Types**: Names should describe the **role** of the entity, not its type.
    *   **Bad**: `var stringArray: [String]`
    *   **Good**: `var searchTerms: [String]`

### Protocols and Types
*   **Protocols describing *what* something is**: Should be nouns (e.g., `Collection`, `Widget`).
*   **Protocols describing *capability***: Should end in `-able`, `-ible`, or `-ing` (e.g., `Equatable`, `Drawable`, `Cancellable`).

---

## 3. The "Swifty" API Interface

### Argument Labels
A well-designed Swift function should read like a sentence at the call site.

```swift
// call site
visualizer.draw(container, at: index)
// vs
visualizer.drawContainerAtIndex(container, index) // ❌ Un-Swifty
```

### Preference for Properties over Methods
Use a **computed property** instead of a method if:
1.  The value is intrinsic to the object.
2.  It has `O(1)` complexity (is fast).
3.  It doesn't have side effects.

```swift
extension Blueprint {
    var isActive: Bool {
        // Simple logic
    }
}
```

---

## 4. SwiftUI Idioms
*   **Opaque Types**: Always use `some View`.
*   **View Modifiers**: Favor small, reusable view modifiers over large complex views.
*   **Task/Async**: Use `.task` instead of `onAppear` for asynchronous work.

---

## 5. Exercise: Refactoring your Core
Review your `GraphSimulator.swift`. Is the API clear at the point of use? Does `step()` mean "step the simulation"? Should it be `stepSimulation()`?

**Architect Rule**: If you have to write a comment to explain what a variable name means, the name is likely wrong.
