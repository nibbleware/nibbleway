import { z } from "zod";

// --- C4 Model: Value Objects ---

export const SystemDefinitionSchema = z.object({
    name: z.string(),
    description: z.string(),
});

export const ContainerSchema = z.object({
    id: z.string(),
    name: z.string(),
    type: z.enum(["Agent", "MCP Server", "Database", "Service"]),
    technology: z.string().optional(),
    api_spec: z.string().describe("Path to OpenAPI or Interface definition"),
    execution: z.object({
        type: z.enum(["local", "docker", "sse"]),
        command: z.string().optional(),
        args: z.array(z.string()).optional(),
        env: z.record(z.string()).optional(),
        url: z.string().optional(),
    }).optional(),
});

export const RelationshipSchema = z.object({
    source: z.string(),
    destination: z.string(),
    description: z.string(),
    protocol: z.string().optional(),
});

export const PolicySchema = z.object({
    id: z.string(),
    format: z.enum(["rego", "json", "custom"]),
    source: z.string(),
});

// --- Root Blueprint ---

export const BlueprintSchema = z.object({
    version: z.string(),
    system: SystemDefinitionSchema,
    containers: z.array(ContainerSchema),
    relationships: z.array(RelationshipSchema),
    policies: z.array(PolicySchema).optional().default([]),
});

export type Blueprint = z.infer<typeof BlueprintSchema>;
export type Container = z.infer<typeof ContainerSchema>;
export type Relationship = z.infer<typeof RelationshipSchema>;
