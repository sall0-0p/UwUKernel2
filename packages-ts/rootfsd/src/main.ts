import {fs, proc, ipc} from "libsystem.raw";

fs.write(2 as FileDescriptor, `Hello from ${proc.info().name} (${proc.info().pid})!`);
ipc.send(0 as PortId, { status: "OK" });
proc.exit(0);