import {ExecutionService} from "../execute/ExecutionService";
import {fs, proc} from "libsystem.raw";
import {IService} from "./ServiceRegistry";

export namespace ServiceStarter {
    export function start(service: IService, fds: proc.FileDescriptorTable) {
        try {
            const definition = service.definition;
            const executable = definition.Exec.Path;
            const properties = fs.stat(executable);

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
                fds: fds,
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