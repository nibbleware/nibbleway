import fs from "fs";
import path from "path";
import yaml from "js-yaml";
import { BlueprintSchema, type Blueprint } from "./schema.js";

export class BlueprintManager {
    private blueprint: Blueprint | null = null;
    private filePath: string;

    constructor(filePath: string) {
        this.filePath = filePath;
    }

    public async load(): Promise<Blueprint> {
        console.error(`Loading Blueprint from: ${this.filePath}`);

        if (!fs.existsSync(this.filePath)) {
            throw new Error(`Blueprint file not found at: ${this.filePath}`);
        }

        const fileContent = fs.readFileSync(this.filePath, "utf8");
        const parsed = yaml.load(fileContent);

        // Validate against Zod Schema
        const result = BlueprintSchema.safeParse(parsed);

        if (!result.success) {
            console.error("Blueprint Validation Failed:", result.error.format());
            throw new Error("Invalid Blueprint Schema");
        }

        this.blueprint = result.data;
        console.error(`✅ Blueprint Loaded: ${this.blueprint.system.name} (${this.blueprint.version})`);
        console.error(`   - Containers: ${this.blueprint.containers.length}`);
        console.error(`   - Flows: ${this.blueprint.relationships.length}`);

        return this.blueprint;
    }

    public getBlueprint(): Blueprint | null {
        return this.blueprint;
    }

    // --- Helper Lookups ---

    public getContainer(id: string) {
        return this.blueprint?.containers.find((c) => c.id === id);
    }

    public isFlowAllowed(sourceId: string, destId: string): boolean {
        // 1. Check strict Blueprint flow definition
        return this.blueprint?.relationships.some(
            (r) => r.source === sourceId && r.destination === destId
        ) ?? false;
    }
}
