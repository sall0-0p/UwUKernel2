import * as utils from "libsystem.utils";
import {fs, ipc, proc, sys} from "libsystem.raw";

const parsedArgs: { message?: string } = utils.parseArguments(arg, {
    "message": true,
    "m": "@message",
});

const name = proc.info().name;
if (name == "exampled") {
    const file = fs.open("/exampled.log", "w");
    fs.close(file)

    const newFile = fs.open("/exampled.log", "a");
    fs.write(newFile, `Hello from ${name} \n`);
    fs.write(newFile, `Old fd: ${file}, new fd: ${newFile} \n`);
    fs.close(newFile);
}

if (name == "dependencyd") {
    const timerPort = ipc.create();
    sys.timer(timerPort, 5);
    ipc.receive(timerPort);
    ipc.send(0 as PortId, { status: "ready" })
}