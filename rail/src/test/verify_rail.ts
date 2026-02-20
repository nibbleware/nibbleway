import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import { CallToolRequestSchema } from "@modelcontextprotocol/sdk/types.js";

async function main() {
    console.log("🚂 Starting Mock Provider (Client)...");

    // Connect to the Rail Server
    const transport = new StdioClientTransport({
        command: "npx",
        args: ["tsx", "src/index.ts"],
    });

    const client = new Client(
        {
            name: "mock-provider",
            version: "1.0.0",
        },
        {
            capabilities: {},
        }
    );

    await client.connect(transport);
    console.log("✅ Connected to Rail.");

    // Test 1: Allowed Flow (Triage -> Billing)
    console.log("\n🧪 Test 1: Checking Allowed Flow (Triage -> Billing)...");
    try {
        const result1 = await client.callTool(
            {
                name: "govern_transaction",
                arguments: {
                    source_agent_id: "triage-agent",
                    destination_resource: "billing-agent",
                    action: "handoff",
                },
            }
        );
        console.log("Result:", JSON.stringify(result1, null, 2));
    } catch (e) {
        console.error("Test 1 Failed:", e);
    }

    // Test 2: Blocked Flow (Triage -> Stripe)
    console.log("\n🧪 Test 2: Checking Blocked Flow (Triage -> Stripe)...");
    try {
        const result2 = await client.callTool(
            {
                name: "govern_transaction",
                arguments: {
                    source_agent_id: "triage-agent",
                    destination_resource: "stripe-integration", // Direct access disallowed
                    action: "call",
                },
            }
        );
        console.log("Result:", JSON.stringify(result2, null, 2));
    } catch (e) {
        console.log("Test 2 Blocked (Expected):", e); // It might not throw, but return a BLOCK verdict
    }

    await client.close();
}

main().catch(console.error);
