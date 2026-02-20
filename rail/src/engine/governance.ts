import { BlueprintManager } from "../blueprint/manager.js";

export type Verdict = "ALLOW" | "BLOCK";

export interface GovernanceResult {
    verdict: Verdict;
    reason: string;
}

export class GovernanceEngine {
    private blueprintManager: BlueprintManager;

    constructor(blueprintManager: BlueprintManager) {
        this.blueprintManager = blueprintManager;
    }

    public evaluate(sourceId: string, destinationId: string, action: string): GovernanceResult {
        // 1. Check if Source Agent exists
        const source = this.blueprintManager.getContainer(sourceId);
        if (!source) {
            return { verdict: "BLOCK", reason: `Source Agent '${sourceId}' not found in Blueprint.` };
        }

        // 2. Check if Destination exists
        const dest = this.blueprintManager.getContainer(destinationId);
        if (!dest) {
            // Ideally we block unknown destinations, but for MVP maybe we strictly enforce?
            return { verdict: "BLOCK", reason: `Destination '${destinationId}' not found in Blueprint.` };
        }

        // 3. Check Flow
        const allowed = this.blueprintManager.isFlowAllowed(sourceId, destinationId);

        if (allowed) {
            return { verdict: "ALLOW", reason: "Flow explicitly defined in Blueprint." };
        } else {
            return { verdict: "BLOCK", reason: "No established relationship in Blueprint." };
        }
    }
}
