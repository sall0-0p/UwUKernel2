import {IService} from "../ServiceRegistry";

export namespace BootManager {
    export function getStages(services: Map<string, IService>): string[][] {
        const toBoot: Set<string> = new Set();
        const adjList: Map<string, string[]> = new Map();
        const inDegree: Map<string, number> = new Map();

        // determine which processes we even care about
        const queue: string[] = [];
        services.forEach((service, name) => {
            adjList.set(name, []);
            inDegree.set(name, 0);
            queue.push(name);
        });

        // recursively include dependencies of processes we care about
        while (queue.length > 0) {
            const curr = queue.shift()!;
            if (toBoot.has(curr)) continue;
            toBoot.add(curr);

            const svc = services.get(curr);
            if (svc && svc.definition.Dependencies) {
                const deps = svc.definition.Dependencies;
                if (deps.Requires) deps.Requires.forEach(d => queue.push(d));
                if (deps.Wants) deps.Wants.forEach(d => queue.push(d));
            }
        }

        // building graph
        for (const name of toBoot) {
            adjList.set(name, []);
            inDegree.set(name, 0);
        }

        for (const name of toBoot) {
            const svc = services.get(name);
            if (!svc || !svc.definition.Dependencies) continue;
            const deps = svc.definition.Dependencies;

            // After -> must start before `name`
            if (deps.After) {
                for (const dep of deps.After) {
                    if (toBoot.has(dep)) {
                        adjList.get(dep)!.push(name);
                        inDegree.set(name, inDegree.get(name)! + 1);
                    }
                }
            }

            // Before -> `name` must start before
            if (deps.Before) {
                for (const dep of deps.Before) {
                    if (toBoot.has(dep)) {
                        adjList.get(name)!.push(dep);
                        inDegree.set(dep, inDegree.get(dep)! + 1);
                    }
                }
            }
        }

        // sort it
        const stages: string[][] = [];
        let currentStage: string[] = [];

        // everyone without dependencies
        for (const [name, degree] of inDegree.entries()) {
            if (degree === 0) {
                currentStage.push(name);
            }
        }

        let processedCount = 0;
        while (currentStage.length > 0) {
            stages.push(currentStage);
            processedCount += currentStage.length;

            const nextStage: string[] = [];
            for (const node of currentStage) {
                const neighbors = adjList.get(node)!;
                for (const neighbor of neighbors) {
                    const degree = inDegree.get(neighbor)! - 1;
                    inDegree.set(neighbor, degree);

                    // If all dependencies for this neighbor are met, it boots in the next stage
                    if (degree === 0) {
                        nextStage.push(neighbor);
                    }
                }
            }

            currentStage = nextStage;
        }

        if (processedCount < toBoot.size) {
            const cycleServices = Array.from(toBoot).filter(name => inDegree.get(name)! > 0);
            error(`ECYCLE: Circular dependency detected involving: ${cycleServices.join(", ")}`);
        }

        return stages;
    }
}