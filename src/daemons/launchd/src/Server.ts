import { io, ipc, proc, sync, task } from "libsystem.raw";
import { IService, ServiceRegistry } from "./service/ServiceRegistry";
import { ExecutionService } from "./execute/ExecutionService";

export namespace Server {
    let stateMutex: SyncHandle;
    let stageCond: SyncHandle;

    function findServiceByPid(pid: number): IService | null {
        let foundService: IService | null = null;
        ServiceRegistry.getServices().forEach((s) => {
            if (s.pid === pid) foundService = s;
        });
        return foundService;
    }

    function findServiceByName(name: string): IService | null {
        return ServiceRegistry.getServices().get(name) || null;
    }

    function sendError(replyPort: any, errorMessage: string) {
        ipc.send(replyPort, { success: false, error: errorMessage }, { type: "launchd_response" });
    }

    function handleReady(message: any) {
        const service = findServiceByPid(message.pid);
        if (!service) return;

        sync.lock(getMutex());
        service.status = "running";
        sync.notify(getCond(), true);
        sync.unlock(getMutex());
    }

    function handleDiscover(message: any) {
        if (!message.reply) return;

        const serviceName: string = message.data?.service;
        if (!serviceName) {
            sendError(message.reply, "Invalid service name!");
            return;
        }

        const service = findServiceByName(serviceName);
        if (!service) {
            sendError(message.reply, "Service not found!");
            return;
        }

        if (service.status === "off" || service.status === "dead") {
            const handle = io.dup(service.ipcPort);
            ipc.send(message.reply, { success: true }, {
                transfer: [handle],
                type: "launchd_response",
            });
            return;
        }

        sendError(message.reply, "Service is off/dead!");
    }

    function handleSpawn(message: any) {
        if (!message.reply) return;

        const sender = proc.info(message.pid);
        const credentials = {
            uid: sender.uid,
            gid: sender.gid,
            groups: sender.groups,
        };

        const data: {
            path: string,
            args?: string[],
            env?: Record<string, string>,
            cwd?: string,
            fds?: proc.FileDescriptorTable,
            uid?: number,
            gid?: number,
            groups?: number[],
            name?: string,
            limits?: Partial<proc.ProcessLimits>,
        } = message.data;

        const requiresRoot = data.uid !== null || data.gid !== null || data.groups !== null || data.limits !== null;

        if (requiresRoot && credentials.uid !== 0) {
            sendError(message.reply, "No permissions!");
            return;
        }

        try {
            const pid = ExecutionService.execute(message.pid, data.path, data.args ?? [], credentials, {
                env: data.env,
                cwd: data.cwd,
                fds: data.fds,
                uid: data.uid,
                gid: data.gid,
                groups: data.groups,
                name: data.name,
                limits: data.limits,
            });

            if (pid) {
                ipc.send(message.reply, { success: true, pid: pid }, { type: "launchd_response" });
            }
        } catch (e) {
            sendError(message.reply, `Something went wrong! ${e}`);
        }
    }

    export function run(controlPort: PortId) {
        while (true) {
            const message = ipc.receive(controlPort);

            if (message.type === "launchd_ready") {
                handleReady(message);
            } else if (message.type === "launchd_discover") {
                handleDiscover(message);
            } else if (message.type === "launchd_spawn") {
                handleSpawn(message);
            } else if (message.reply) {
                sendError(message.reply, "Invalid method!");
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