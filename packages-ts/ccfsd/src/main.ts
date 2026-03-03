import {ipc, proc} from "libsystem.raw";
import * as utils from "libsystem.utils";

print(`Hello from ${proc.info().name} (${proc.info().pid})!`);

const parsedArgs = utils.parseArguments(arg, {
    "volume": true,
    "v": "@volume",
    "path": true,
});

for (const key in parsedArgs) {
    print(`${key}: "${parsedArgs[key]}"`);
}

ipc.send(0 as PortID, { status: "OK" });
proc.exit(0);