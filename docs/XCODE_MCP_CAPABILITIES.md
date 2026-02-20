# Xcode MCP Capability Report: Nibbleway Integration

This report outlines the capabilities discovered within the Xcode MCP ecosystem and how they can be leveraged to enhance the **Nibbleway Studio** and general agentic workflows.

## 1. Xcode Internal Tool Service (`mcpbridge`)

The `mcpbridge` (accessible via `xcrun mcpbridge`) acts as a bridge between MCP clients and Xcode's internal tool orchestration. It exposes several high-value tools:

### Build & Test
- **`BuildProject`**: Builds the active scheme.
- **`RunAllTests`**: Executes the full test suite.
- **`RunSomeTests`**: Targeted testing via test plans.
- **`GetBuildLog` / `GetIssues`**: Retrieves results and diagnostics.

### Code Execution & Prototyping
- **`ExecuteSnippet`**: [POWERFUL] Compiles and runs a Swift snippet within the target's context, returning console output.
- **`RenderPreview`**: [POWERFUL] Builds and captures a snapshot of a SwiftUI Preview.

### Project Orchestration
- **`XcodeMV` / `XcodeRM` / `XcodeMakeDir`**: Direct manipulation of the Xcode project structure (groups and files) without manually editing `.xcodeproj` files.
- **`DocumentationSearch`**: Semantic search across Apple Developer Documentation.

---

## 2. Nibbleway Architectural Integration

### Current Capabilities (`MCPManager.swift`)
The Studio app already integrates with the Xcode bridge but currently only maps a subset of tools:
- `BuildProject`
- `RunAllTests`
- `GetBuildLog`

### Planned/Possible Extensions
- **Policy Enforcement**: Using the `ExecuteSnippet` tool to verify that new code conforms to architecture (e.g., checking if a class inherits from a required base).
- **UI Validation**: Using `RenderPreview` to automatically verify that a generated UI matches the Blueprint's requirements.
- **Automated Refactoring**: Using `XcodeMV` and `XcodeMakeDir` to reorganize the project into the "Feature-Based Directory Pattern" documented in the architectural guides.

---

## 3. The Nibbleway "Control Plane"

### `ArchitectContextServer`
A custom server that exposes Nibbleway-specific context (e.g., approved vendors via `get_approved_vendors`) to external agents. This allows Xcode-based agents to make "informed" decisions based on the company's registry.

### `nibbleway-rail`
A governance server that evaluates transactions (like an agent trying to call a restricted tool) against the Blueprint. This provides-safety rails for automated interactions.

---

## Next Steps for the Project
1. **Expand `MCPManager.swift`**: Add support for the remaining found tools (`ExecuteSnippet`, `RenderPreview`, etc.).
2. **Unified Transport**: Ensure `ArchitectContextServer` is properly exposed via Stdio or SSE so external agents can consume it alongside Xcode's tools.
3. **Draft Workflows**: Create agentic workflows that chain these tools (e.g., "Draft UI -> Render Preview -> Validate against Policy -> Commit").
