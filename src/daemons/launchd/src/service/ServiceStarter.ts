import {ExecutionService} from "../execute/ExecutionService";
import {fs, proc} from "libsystem.raw";
import {IService} from "./ServiceRegistry";

export namespace ServiceStarter {
    export function start(service: IService, fds: proc.FileDescriptorTable) {
        try {
            const definition = service.definition;
            const executable = definition.Exec.Path;

            let defaultUid = 0;
            let defaultGid = 0;
            if (!definition.Exec.Blob) {
                const properties = fs.stat(executable);
                defaultUid = properties.uid;
                defaultGid = properties.gid;
            }

            // start the thing
            service.pid = ExecutionService.execute(1, executable, definition.Exec.Arguments || [], { uid: defaultUid, gid: defaultGid, groups: [] }, {
                env: definition.Environment ?? {},
                uid: definition.User?.User ?? defaultUid,
                gid: definition.User?.Group ?? defaultGid,
                cwd: definition.Exec.WorkingDir ?? "/",
                name: definition.Service.Name,
                limits: {
                    maxPorts: definition.Limits?.MaxPorts ?? 1024,
                    maxThreads: definition.Limits?.MaxThreads ?? 1024,
                    maxFiles: definition.Limits?.MaxFiles ?? 16,
                    maxProcesses: definition.Limits?.MaxProcesses ?? 16,
                },
                fds: fds,
                blob: definition.Exec.Blob,
                preload: definition.Exec.Preload,
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