import {IService} from "./ServiceRegistry";
import {fs, ipc, task} from "libsystem.raw";
import {ServiceStarter} from "./ServiceStarter";

export namespace SocketActivator {
    function listen(service: IService, controlPort: PortId) {
        service.status = "listening";

        // Creating separate thread for this.
        task.create(() => {
            // Wait for one of ports of this process to receive something
            ipc.poll([service.ipcPort, service.mountPort] as PortId[]);

            ServiceStarter.start(service, {
                [0]: controlPort,
                [4]: service.ipcPort,
                [5]: service.mountPort
            })
        })
    }

    export function process(service: IService, controlPort: PortId) {
        const definition = service.definition;
        const executable = definition.Exec.Path;
        const properties = fs.stat(executable);

        service.ipcPort = ipc.create();
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

        listen(service, controlPort);
    }
}