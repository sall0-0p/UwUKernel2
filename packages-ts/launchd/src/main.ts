import {dev, fs, proc, ipc, io} from "libsystem.raw";

const terminal = dev.open("terminal");
const stdout = io.dup(terminal, 2);

fs.write(stdout, `Hello from ${proc.info().name} (${proc.info().pid})!`);

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
// Wait for ccfsd to start
ipc.receive(mailbox);

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
// Wait for ccfsd to start
ipc.receive(mailbox);

proc.spawn("/System/rootfsd/init.lua", [ "--volumes", "/dev/vol0", "/dev/vol1", "--path", "/" ], {
    name: "rootfsd",
    blob: rootfsdBlob,
    // @ts-ignore
    preload: package.preload,
    fds: {
        [0]: mailbox as FileDescriptor,
        [2]: terminal,
    }
})
// Wait for rootfsd to start
ipc.receive(mailbox);

while (proc.info().children.length > 0) {
    const result = proc.wait(-1);
    print(`Process ${result.pid} finished with code ${result.code}! It ran for ${result.usage}`);
}

print("Launchd exiting!");
proc.exit(0);