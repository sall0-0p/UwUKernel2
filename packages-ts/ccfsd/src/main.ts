import {fs, ipc, proc} from "libsystem.raw";
import * as utils from "libsystem.utils";
import {IExpectedArguments} from "./interfaces/IExpectedArguments";
import {FileSystemServer} from "libsystem.vfs";
import {DiskHandlers} from "./DiskHandlers";

print(`Hello from ${proc.info().name} (${proc.info().pid})!`);

// parse arguments
const parsedArgs: IExpectedArguments = utils.parseArguments(arg, {
    "volume": true,
    "v": "@volume",
    "path": true,
});

const server = new FileSystemServer(new DiskHandlers(parsedArgs.volume));
const port = server.getPortId();
fs.mount(parsedArgs.path, port);

ipc.send(0 as PortId, { status: "OK" });
server.start();

proc.exit(0);