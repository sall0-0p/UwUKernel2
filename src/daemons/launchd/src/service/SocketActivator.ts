import {IService} from "./ServiceRegistry";
import {fs, ipc, task} from "libsystem.raw";
import {ServiceStarter} from "./ServiceStarter";

export namespace SocketActivator {
    function listen(service: IService, controlPort: PortId, processReceivePort: PortId) {
        service.status = "listening";

        // Creating separate thread for this.
        task.create(() => {
            // Wait for one of ports of this process to receive something
            ipc.poll([processReceivePort, service.mountPort] as PortId[]);

            ServiceStarter.start(service, {
                [0]: controlPort,
                [2]: 2 as PortId,
                [4]: { fd: processReceivePort, op: "MOVE" },
                [5]: { fd: service.mountPort, op: "MOVE" },
            })
        })
    }

    export function process(service: IService, controlPort: PortId, processReceivePort: PortId) {
        const definition = service.definition;
        const executable = definition.Exec.Path;
        const properties = fs.stat(executable);

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

        listen(service, controlPort, processReceivePort);
    }
}