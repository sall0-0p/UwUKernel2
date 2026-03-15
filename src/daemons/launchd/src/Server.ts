import {ipc, sync, task} from "libsystem.raw";
import {IService, ServiceRegistry} from "./service/ServiceRegistry";

export namespace Server {
    let stateMutex: SyncHandle;
    let stageCond: SyncHandle;

    function findServiceByPid(pid: number): IService | null {
        const services = ServiceRegistry.getServices();
        let service;
        services.forEach((s) => {
            if (s.pid == pid) service = s;
        })

        return service;
    }

    export function run(controlPort: PortId) {
        while (true) {
            const message = ipc.receive(controlPort);
            if (message.data.status === "ready") {
                const senderPid = message.pid;
                const service = findServiceByPid(senderPid);

                if (service) {
                    sync.lock(getMutex());
                    service.status = "running";
                    sync.notify(getCond(), true);
                    sync.unlock(getMutex());
                }
            }
        }
    }

    export function start(controlPort: PortId) {
        return task.create(() => run(controlPort));
    }

    export function getMutex() {
        if (stateMutex === undefined) stateMutex = sync.create("MUTEX");
        return stateMutex;
    }
    export function getCond() {
        if (stageCond === undefined) stageCond = sync.create("COND");
        return stageCond;
    }
}