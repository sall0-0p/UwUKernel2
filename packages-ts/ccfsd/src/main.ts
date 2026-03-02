import {fs, ipc, proc} from "libsystem.raw";

fs.write(2 as FileDescriptor, `Hello from ${proc.info().name} (${proc.info().pid})!`);
ipc.send(0 as PortID, { status: "OK" });
proc.exit(0);