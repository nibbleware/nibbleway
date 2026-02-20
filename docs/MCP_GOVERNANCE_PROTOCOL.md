# MCP Governance Protocol: Architect Context

This guide documents how Nibbleway Studio uses the **Model Context Protocol (MCP)** to govern external agentic development.

---

## 1. The Core Philosophy
In the Nibbleway ecosystem, we don't just "talk" to agents; we **provide the grounding context** they need to build enterprise-compliant code.

The **`ArchitectContextServer`** is the single source of truth for:
*   **Approved Tech Stacks**: (e.g., "Use Apollo GraphQL").
*   **Approved Vendors**: (e.g., "Use Stripe for Payments").
*   **Safety Rails**: Disallowing insecure connections or unapproved data flows.

---

## 2. Server Implementation Details

### Tool Discovery:
When an IDE (Xcode 26.3 or Android Studio) connects to the Studio, it discovers the following tools provided by your `ArchitectContextServer`:

| Tool | Purpose |
| :--- | :--- |
| `get_approved_vendors` | Returns a list of vendors for a category (Payments, Push). |
| `get_active_stack` | Returns the technology stack of the current blueprint. |

---

## 3. The IDE Handshake
For Xcode agents to discover this context, the Studio must be registered as an MCP server.

### Xcode Integration Path:
1.  Studio starts the `ArchitectContextServer`.
2.  Xcode (via its native MCP client) connects to the Studio's port or stdio channel.
3.  The User (Architect) triggers a task in Xcode.
4.  The Xcode Agent calls `get_active_stack` to understand that it should be writing **Apollo GraphQL** code instead of standard REST.

---

## 4. Learning Goals:
1.  **Protocol Standards**: Learn how to define tools using the JSON-RPC nature of MCP.
2.  **Cross-App Communication**: Understand how local processes talk to each other without a central cloud.
3.  **Governance Patterns**: Implementing logic that "refuses" or "redirects" an agent's request based on architectural policies.
