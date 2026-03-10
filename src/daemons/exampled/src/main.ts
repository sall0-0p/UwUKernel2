import * as utils from "libsystem.utils";
import {fs} from "libsystem.raw";

const parsedArgs: { message?: string } = utils.parseArguments(arg, {
    "message": true,
    "m": "@message",
});

const file = fs.open("/exampled.log", "w");
fs.write(file, parsedArgs.message);
fs.close(file);