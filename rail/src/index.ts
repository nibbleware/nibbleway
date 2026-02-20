#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
    CallToolRequestSchema,
    ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import path from "path";
import { BlueprintManager } from "./blueprint/manager.js";
import { GovernanceEngine } from "./engine/governance.js";

// Initialize the MCP Server
const server = new Server(
    {
        name: "nibbleway-rail",
        version: "0.1.0",
    },
    {
        capabilities: {
            tools: {},
        },
    }
);

// List Tools (Governance Capabilities)
server.setRequestHandler(ListToolsRequestSchema, async () => {
    return {
        tools: [
            {
                name: "govern_transaction",
                description: "Evaluates a proposed agent transaction against the Blueprint.",
                inputSchema: {
                    type: "object",
                    properties: {
                        source_agent_id: { type: "string" },
                        destination_resource: { type: "string" },
                        action: { type: "string" },
                    },
                    required: ["source_agent_id", "destination_resource", "action"],
                },
            },
        ],
    };
});

// Global instances
let globalManager: BlueprintManager | undefined;
let globalEngine: GovernanceEngine | undefined;

// Handle Tool Calls (The interception logic)
server.setRequestHandler(CallToolRequestSchema, async (request) => {
    if (request.params.name === "govern_transaction") {
        if (!globalEngine) {
            throw new Error("Governance Engine not initialized");
        }

        const args = request.params.arguments as {
            source_agent_id: string;
            destination_resource: string;
            action: string;
        } | undefined;

        if (!args || !args.source_agent_id || !args.destination_resource) {
            return {
                content: [{ type: "text", text: JSON.stringify({ verdict: "BLOCK", reason: "Missing arguments" }) }]
            };
        }

        const result = globalEngine.evaluate(args.source_agent_id, args.destination_resource, args.action || "call");

        return {
            content: [
                {
                    type: "text",
                    text: JSON.stringify(result),
                },
            ],
        };
    }
    throw new Error("Tool not found");
});

// Start the server
async function main() {
    const transport = new StdioServerTransport();

    // Load Blueprint
    const blueprintPath = process.env.BLUEPRINT_PATH || path.resolve(process.cwd(), "../blueprint_schema.yaml");
    globalManager = new BlueprintManager(blueprintPath);

    try {
        await globalManager.load();
        globalEngine = new GovernanceEngine(globalManager);
    } catch (err) {
        console.error("Failed to load blueprint:", err);
        process.exit(1);
    }

    await server.connect(transport);
    console.error("Nibbleway Rail Server running on stdio");
}

main().catch((error) => {
    console.error("Server error:", error);
    process.exit(1);
});
