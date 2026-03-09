import {IService, ServiceRegistry} from "./ServiceRegistry";
import {BootManager} from "./boot/BootManager";
import {ExecutionService} from "../execute/ExecutionService";
import {fs, ipc, proc} from "libsystem.raw";

export namespace ServiceRunner {
    export function run() {
        const services = ServiceRegistry.getServices();
        const stages = BootManager.getStages(services);

        stages.forEach((stage) => {
            const mapped: IService[] = stage.map((e: string) => services.get(e));
            mapped.forEach((s) => launchService(s));
            // wait for stage to be initialised
        })
    }

    function launchService(service: IService) {
        const definition = service.definition;
        const executable = definition.Exec.Path;
        const properties = fs.stat(executable);

        // Create activation ports
        if (definition.Activation?.Enabled) {
            service.ipcPort = ipc.create();
            service.status = "listening";
            if (definition.Activation.MountPoint && properties.uid == 0) {
                service.mountPort = ipc.create();
                try {
                    fs.mount(definition.Activation.MountPoint, service.mountPort as PortId);
                } catch (e) {
                    service.status = "dead";
                    print(e);
                    return;
                }
            }
        } else {
            try {
                // start the thing
                service.pid = ExecutionService.execute(1, executable, definition.Exec.Arguments || [], { uid: properties.uid, gid: properties.gid, groups: [] }, {
                    env: definition.Environment ?? {},
                    uid: definition.User?.User ?? properties.uid,
                    gid: definition.User?.Group ?? properties.gid,
                    cwd: definition.Exec.WorkingDir ?? "/",
                    name: definition.Service.Name,
                    limits: {
                        maxPorts: definition.Limits?.MaxPorts ?? 1024,
                        maxThreads: definition.Limits?.MaxThreads ?? 1024,
                        maxFiles: definition.Limits?.MaxFiles ?? 16,
                        maxProcesses: definition.Limits?.MaxProcesses ?? 16,
                    },
                    fds: {
                        [0]: 0 as FileDescriptor,
                    }
                });

                // set status according to type, later starting services will be listened upon
                if (definition.Service.Type == "simple") {
                    service.status = "running";
                } else {
                    service.status = "starting";
                }
            } catch (e) {
                service.status = "dead";
                print(e);
                return;
            }
        }
    }
}