import * as utils from "libsystem.utils";

const parsedArgs: { message?: string } = utils.parseArguments(arg, {
    "message": true,
    "m": "@message",
});

print(parsedArgs.message);