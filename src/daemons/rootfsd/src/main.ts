import {fs, proc, ipc, sys} from "libsystem.raw";
import {IExpectedArguments} from "./interfaces/IExpectedArguments";
import * as utils from "libsystem.utils";
import {FileSystemServer} from "libsystem.vfs";
import {FileHandlers} from "./FileHandlers";

const parsedArgs: IExpectedArguments = utils.parseArguments(arg, {
    "volume": true,
    "v": "@volume",
    "path": true,
});

if (!parsedArgs.volume) error("Volume has be specified!");
if (!parsedArgs.path) error("Mount path has to be specified!");

const handlers = new FileHandlers(parsedArgs.volume);
const server = new FileSystemServer(handlers);
const port = server.getPortId();
fs.mount(parsedArgs.path, port);

ipc.send(0 as PortId, {}, {
    type: "launchd_ready",
});
server.start();
proc.exit(0);