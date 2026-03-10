import * as utils from "libsystem.utils";
import {fs, ipc, proc, sys} from "libsystem.raw";

const parsedArgs: { message?: string } = utils.parseArguments(arg, {
    "message": true,
    "m": "@message",
});

const name = proc.info().name;
const pid = proc.info().pid;

if (name == "exampled") {
    print("exampled: Booted up. Waiting 3 seconds for launchd to settle...");

    // Give launchd time to set up socket activators
    const timerPort = ipc.create();
    sys.timer(timerPort, 3);
    ipc.receive(timerPort);
    ipc.close(timerPort);

    print("exampled: Triggering socket activation by opening /Devices/dependencyd...");
    try {
        // This triggers a VFS_OPEN IPC message to the mount port.
        // launchd intercepts this via ipc.poll, spawns dependencyd, and leaves the message in the queue.
        const fd = fs.open("/Devices/dependencyd", "r");
        print(`exampled: Successfully opened socket activated device! fd: ${fd}`);

        print("exampled: Closing the device...");
        fs.close(fd); // Triggers VFS_CLOSE
        print("exampled: Closed successfully. Done!");
    } catch (e) {
        print(`exampled: Failed to open dependencyd - ${e}`);
    }
}

if (name == "dependencyd") {
    print("dependencyd: Woke up via socket activation!");

    // launchd explicitly passes the triggered mount port on FD 5
    const mountPort = 5 as any;

    // Process the queued messages that woke us up
    while (true) {
        const msg = ipc.receive(mountPort);

        if (msg.type === "VFS_OPEN") {
            print("dependencyd: Received VFS_OPEN. Replying to unblock client.");
            // Reply with a mock file handle ID to satisfy VFSManager
            ipc.send(msg.reply as any, { status: "OK", data: { fileId: 1, size: 0 } });
        } else if (msg.type === "VFS_CLOSE") {
            print("dependencyd: Received VFS_CLOSE. Replying and shutting down.");
            ipc.send(msg.reply as any, { status: "OK" });

            break; // Exit the daemon once closed
        } else {
            print(`dependencyd: Received unsupported VFS request: ${msg.type}`);
            ipc.send(msg.reply as any, { status: "ERROR", data: "Unsupported operation" });
        }
    }

    print("dependencyd: Exiting cleanly.");
}