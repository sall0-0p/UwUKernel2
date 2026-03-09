import {ServiceRegistry} from "./ServiceRegistry";

export namespace ServiceRunner {
    export function run() {
        const services = ServiceRegistry.getServices();

    }
}