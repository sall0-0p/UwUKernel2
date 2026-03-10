import * as utils from "libsystem.utils";
import {fs, proc} from "libsystem.raw";

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