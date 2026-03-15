import {IService, ServiceRegistry} from "./ServiceRegistry";
import {BootManager} from "./boot/BootManager";
import {io, ipc, sync, task} from "libsystem.raw";
import {SocketActivator} from "./SocketActivator";
import {ServiceStarter} from "./ServiceStarter";
import {Server} from "../Server";

export namespace ServiceRunner {
    function allServicesRunning(stage: IService[]) {
        let running = true;
        stage.forEach((s) => {
            running = s.status == "running" && running;
        })
        return running;
    }

    function waitForStage(stage: IService[]) {
        const stateMutex = Server.getMutex();
        const stageCond = Server.getCond();
        sync.lock(stateMutex);

        while (!allServicesRunning(stage)) {
            sync.wait(stageCond, stateMutex);
        }

        sync.unlock(stateMutex);

        print("Stage started!");
    }

    export function run(controlPort: PortId) {
        const services = ServiceRegistry.getServices();
        const stages = BootManager.getStages(services);

        // start each stage
        stages.forEach((stage) => {
            const mapped: IService[] = stage.map((e: string) => services.get(e));
            const threads: ThreadId[] = [];

            // start each thread in separate thread, and wait for their ready state, do it concurrently.
            mapped.forEach((s) => {
                const tid = task.create(launchService, [s, controlPort]);
                threads.push(tid);
            });

            // join all the threads
            while (threads.length > 0) {
                task.join(threads.pop());
            }

            waitForStage(mapped);
        })
    }

    function launchService(service: IService, controlPort: PortId, restarting?: boolean) {
        const definition = service.definition;

        // Lets not relaunch services that are already running.
        // if off or (dead and restarting)
        if (!(service.status == "off" || (service.status == "dead" && restarting))) return;
        const processReceivePort = ipc.create();
        service.ipcPort = io.dup(processReceivePort);

        // Create activation ports
        if (definition.Activation?.Enabled) {
            SocketActivator.process(service, controlPort, processReceivePort);
        } else {
            ServiceStarter.start(service, {
                [0]: controlPort,
                [2]: 2 as PortId,
                [4]: { fd: processReceivePort, op: "MOVE" },
            })
        }
    }

    export function restart(service: IService, services: Map<string, IService>, controlPort: number) {
        const requirements = service.definition.Dependencies?.Requires || [];
        for (const req of requirements) {
            const dep = services.get(req);
            if (!dep || dep.status === "dead" || dep.status === "off") {
                print(`Restart aborted for ${service.definition.Service.Name}: Requirement '${req}' is dead.`);
                return;
            }
        }

        print(`Restarting service: ${service.definition.Service.Name}...`);

        service.pid = undefined;
        service.ipcPort = undefined;
        service.mountPort = undefined;

        launchService(service, controlPort as PortId);
    }
}