import * as ipc from "ipc";
import * as proc from "proc";
import * as fs from "fs";

fs.write(2 as FileDescriptor, `Hello from ${proc.info().name} (${proc.info().pid})!`);
ipc.send(0 as PortID, { status: "OK" });
proc.exit(0);