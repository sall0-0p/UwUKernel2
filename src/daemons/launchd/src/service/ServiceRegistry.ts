import {IServiceDefinition} from "./IServiceDefinition";
import {fs} from "libsystem.raw";
import * as toml from "libsystem.toml";

export interface IService {
    pid?: number,
    ipcPort?: number,
    mountPort?: number,
    definition: IServiceDefinition,
    status: "running" | "listening" |  "starting" | "dead" | "off",
    dependants: Set<string>,
}

export namespace ServiceRegistry {
    const services: Map<string, IService> = new Map();

    export function discover(path: string) {
        if (!fs.stat(path)) error("Invalid path to configs!", 2);
        const files: string[] = fs.list(path);
        files.forEach((fileName) => {
            const file = fs.open(path + "/" + fileName, "r");
            const config = fs.read(file, 32768);
            const def = toml.decode(config) as IServiceDefinition;

            fs.close(file);
            if (def.Exec.Blob) {
                // I do not allow blobs in configs, use filesystem
                return;
            }
            services.set(def.Service.Name, {
                definition: def,
                status: "off",
                dependants: new Set(),
            });
        });
    }

    export function resolveDependencies(services: Map<string, IService>) {
        // Initialise
        services.forEach((service: IService) => {
            if (!service.dependants) service.dependants = new Set<string>();
        });

        // Build dependency graph
        services.forEach((service, name) => {
            const requirements = service.definition.Dependencies?.Requires || [];
            requirements.forEach((requirement) => {
                const dependency = services.get(requirement);
                if (dependency) {
                    dependency.dependants.add(name);
                }
            });
        });

        // Clear all with dead requirements
        const deadQueue: string[] = [];
        services.forEach((service, name) => {
            if (service.status === "dead") return;

            const requirements = service.definition.Dependencies?.Requires || [];
            for (const req of requirements) {
                const dep = services.get(req);
                if (!dep || dep.status === "dead") {
                    print(`Dependency ${req} unsatisfied for ${name}`);
                    service.status = "dead";
                    deadQueue.push(name);
                    break;
                }
            }
        });

        // Cascade it
        while (deadQueue.length > 0) {
            const deadServiceName = deadQueue.shift()!;
            const deadService = services.get(deadServiceName);

            if (deadService && deadService.dependants) {
                deadService.dependants.forEach((dependentName) => {
                    const dependentService = services.get(dependentName);
                    // If the dependent isn't already dead, kill it and queue it
                    if (dependentService && dependentService.status !== "dead") {
                        print(`Cascading failure: ${dependentName} died because requirement ${deadServiceName} failed.`);
                        dependentService.status = "dead";
                        deadQueue.push(dependentName);
                    }
                });
            }
        }
    }

    export function registerSynthetic(name: string, def: IServiceDefinition) {
        services.set(name, {
            definition: def,
            status: "off",
            dependants: new Set(),
        });
    }

    export function getServices() {
        return services;
    }
}