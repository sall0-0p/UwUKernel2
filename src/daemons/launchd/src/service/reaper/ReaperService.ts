import {ipc, proc, sys, task} from "libsystem.raw";
import {IService} from "../ServiceRegistry";
import { ServiceRunner } from "../ServiceRunner";

export namespace ReaperService {
    function reap(services: Map<string, IService>, controlPort: number) {
        while (true) {
            const exited = proc.wait(-1);
            let service: IService;
            services.forEach((s) => {
                if (s.pid == exited.pid) service = s;
            })

            if (service) {
                service.status = "dead";

                // Kill dependencies of this process.
                service.dependants.forEach((s) => {
                    const dependant = services.get(s);
                    if (dependant && dependant.pid) {
                        proc.kill(dependant.pid as ProcessId, proc.Signal.SIGTERM);

                        // Kill if did not die in 5 seconds
                        task.create(() => {
                            const pid = dependant.pid;
                            const timer = ipc.create();
                            sys.timer(timer, 5);
                            ipc.receive(timer);
                            ipc.close(timer);

                            if (dependant.status != "dead" && dependant.pid == pid) {
                                proc.kill(dependant.pid as ProcessId, proc.Signal.SIGKILL);
                            }
                        })
                    }
                })

                // Restart if policy allows
                const policy = service.definition.Restart?.Policy;
                const delay = service.definition.Restart?.Delay ?? 0;
                if (policy && policy != "no") {
                    task.create(() => {
                        if (policy == "on-failure" && exited.code == 0) return;
                        if (delay > 0) {
                            const timer = ipc.create();
                            sys.timer(timer, delay);
                            ipc.receive(timer);
                            ipc.close(timer);
                        }

                        ServiceRunner.restart(service, services, controlPort);
                    });
                }
            }
        }
    }

    export function start(services: Map<string, IService>, controlPort: number) {
        return task.create(() => reap(services, controlPort));

    }
}