import {IServiceDefinition} from "./IServiceDefinition";
import {fs} from "libsystem.raw";
import * as toml from "libsystem.toml";

export interface IService {
    pid?: number,
    ipcPort?: number,
    mountPort?: number,
    definition: IServiceDefinition,
    status: "running" | "starting" | "dead" | "off"
}

export namespace ServiceRegistry {
    const services: Map<string, IService> = new Map();

    export function discover(path: string) {
        if (!fs.stat(path)) error("Invalid path to configs!", 2);
        const files: string[] = fs.list(path);
        files.forEach((fileName) => {
            const file = fs.open(path + "/" + fileName, "r");
            const config = fs.read(file, 32768);

            fs.close(file);
            services.set(fileName.replace(".toml", ""), {
                definition: toml.decode(config) as IServiceDefinition,
                status: "off",
            });
        })
    }

    export function getServices() {
        return services;
    }
}