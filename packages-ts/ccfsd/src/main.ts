import {ipc, proc} from "libsystem.raw";
import * as utils from "libsystem.utils";
import {IExpectedArguments} from "./interfaces/IExpectedArguments";

print(`Hello from ${proc.info().name} (${proc.info().pid})!`);

// parse arguments
const parsedArgs: IExpectedArguments = utils.parseArguments(arg, {
    "volume": true,
    "v": "@volume",
    "path": true,
});


ipc.send(0 as PortId, { status: "OK" });
proc.exit(0);