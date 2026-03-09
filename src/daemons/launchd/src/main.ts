import {dev, fs, proc, ipc, io, sys, task} from "libsystem.raw";
import * as toml from "libsystem.toml";
import {ServiceRegistry} from "./service/ServiceRegistry";
import {ServiceRunner} from "./service/ServiceRunner";

const terminal = dev.open("terminal");
const stdout = io.dup(terminal, 2);

// printing system info
fs.ioctl(terminal, "clear", 4);
fs.ioctl(terminal, "setTextColor", 4);
fs.ioctl(terminal, "setCursorPos", 1, 1);
fs.write(terminal, `| ${sys.info().version} \n`);
fs.ioctl(terminal, "setTextColor", 1);

// loading blobs
const ccfsdBlob: string = arg['ccfsd'];
const rootfsdBlob: string = arg['rootfsd'];

const mailbox = ipc.create();

// spawn ccfsd for volume 1 (system)
proc.spawn("/System/ccfsd/init.lua", [ "-v", "volume:system", "--path", "/dev/vol0" ], {
    name: "sysvold",
    blob: ccfsdBlob,
    // @ts-ignore
    preload: package.preload,
    fds: {
        [0]: mailbox as FileDescriptor,
        [2]: terminal,
    }
})

ipc.receive(mailbox);
print("Received on mailbox for sysvold!");

proc.spawn("/System/ccfsd/init.lua", [ "-v", "volume:data", "--path", "/dev/vol1" ], {
    name: "datavold",
    blob: ccfsdBlob,
    // @ts-ignore
    preload: package.preload,
    fds: {
        [0]: mailbox as FileDescriptor,
        [2]: terminal,
    }
})

ipc.receive(mailbox);
print("Received on mailbox for datavold!");

proc.spawn("/System/rootfsd/init.lua", [ "--volume", "/dev/vol0", "--path", "/System" ], {
    name: "systemfsd",
    blob: rootfsdBlob,
    // @ts-ignore
    preload: package.preload,
    fds: {
        [0]: mailbox as FileDescriptor,
        [2]: terminal,
    }
})

ipc.receive(mailbox);
print("Received on mailbox for systemfsd!");

proc.spawn("/System/rootfsd/init.lua", [ "--volume", "/dev/vol1", "--path", "/" ], {
    name: "systemfsd",
    blob: rootfsdBlob,
    // @ts-ignore
    preload: package.preload,
    fds: {
        [0]: mailbox as FileDescriptor,
        [2]: terminal,
    }
})

ipc.receive(mailbox);
print("Received on mailbox for datafsd!");

print("Created reaper!");
const reaper = task.create(() => {
    while (proc.info().children.length > 0) {
        const result = proc.wait(-1);
        print(`Process ${result.pid} finished with code ${result.code}! It ran for ${result.usage}`);
    }
})

ServiceRegistry.discover("/System/Config/Services");
ServiceRegistry.getServices().forEach((s, n) => print(n));
ServiceRunner.run();

print(mailbox);

task.join(reaper);
print("Launchd exiting!");
proc.exit(0);