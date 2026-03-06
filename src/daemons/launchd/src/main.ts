import {dev, fs, proc, ipc, io, sys, task} from "libsystem.raw";

const terminal = dev.open("terminal");
const stdout = io.dup(terminal, 2);

// printing system info
fs.ioctl(terminal, "clear", 4);
fs.ioctl(terminal, "setTextColor", 4);
fs.ioctl(terminal, "setCursorPos", 1, 1);
fs.write(terminal, `| ${sys.info().version} \n`);
fs.ioctl(terminal, "setTextColor", 1);

fs.write(stdout, `Hello from ${proc.info().name} (${proc.info().pid})! \n`);

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

proc.spawn("/System/rootfsd/init.lua", [ "--volume", "/dev/vol0", "--path", "/" ], {
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
print("Received on mailbox for rootfsd!");

print("Created reaper!");
const reaper = task.create(() => {
    while (proc.info().children.length > 0) {
        const result = proc.wait(-1);
        print(`Process ${result.pid} finished with code ${result.code}! It ran for ${result.usage}`);
    }
})

fs.mkdir("/test/");

const wfile = fs.open("/test/world.txt", "w");
fs.write(wfile, "Hello World!");
fs.close(wfile);

const rfile = fs.open("/test/world.txt", "r");
print(fs.read(rfile, 100000));
fs.close(rfile);

task.join(reaper);
print("Launchd exiting!");
proc.exit(0);