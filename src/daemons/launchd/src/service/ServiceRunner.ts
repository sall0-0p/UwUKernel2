import {IService, ServiceRegistry} from "./ServiceRegistry";
import {BootManager} from "./boot/BootManager";
import {ipc, task} from "libsystem.raw";
import {SocketActivator} from "./SocketActivator";
import {ServiceStarter} from "./ServiceStarter";

export namespace ServiceRunner {
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
        })
    }

    function launchService(service: IService, controlPort: PortId) {
        const definition = service.definition;

        // Lets not relaunch services that are already running.
        if (service.status != "off") return;

        // Create activation ports
        if (definition.Activation?.Enabled) {
            SocketActivator.process(service, controlPort);
        } else {
            ServiceStarter.start(service, {
                [0]: controlPort,
                [2]: 2 as PortId,
            })
        }

        // @ts-ignore because its set in ServiceStarter.start and SocketActivator.process
        if (definition.Service.Type == "notify" && service.status == "starting") {
            const message = ipc.receive(controlPort);
            if (message.data.status && message.data.status == "ready") {
                service.status = "running";
                print("Started", service.definition.Service.Name);
            }
        } else {
            print("Started", service.definition.Service.Name);
        }
    }
}