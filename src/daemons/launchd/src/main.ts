import {dev, fs, proc, ipc, io, sys, task} from "libsystem.raw";
import * as toml from "libsystem.toml";
import {ServiceRegistry} from "./service/ServiceRegistry";
import {ServiceRunner} from "./service/ServiceRunner";
import {ReaperService} from "./service/reaper/ReaperService";

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

ServiceRegistry.registerSynthetic("sysvold", {
    Service: { Name: "sysvold", Type: "notify", Description: "Raw System Volume" },
    Exec: {
        Path: "/System/ccfsd/init.lua",
        Arguments: ["-v", "volume:system", "--path", "/dev/vol0"],
        Blob: ccfsdBlob,
        // @ts-ignore
        Preload: package.preload
    }
});

ServiceRegistry.registerSynthetic("datavold", {
    Service: { Name: "datavold", Type: "notify", Description: "Raw Data Volume" },
    Exec: {
        Path: "/System/ccfsd/init.lua",
        Arguments: ["-v", "volume:data", "--path", "/dev/vol1"],
        Blob: ccfsdBlob,
        // @ts-ignore
        Preload: package.preload
    }
});

ServiceRegistry.registerSynthetic("systemfsd", {
    Service: { Name: "systemfsd", Type: "notify", Description: "System VFS Mount" },
    Exec: {
        Path: "/System/rootfsd/init.lua",
        Arguments: ["--volume", "/dev/vol0", "--path", "/System"],
        Blob: rootfsdBlob,
        // @ts-ignore
        Preload: package.preload
    },
    Dependencies: { Requires: ["sysvold"], After: ["sysvold"] }
});

ServiceRegistry.registerSynthetic("datafsd", {
    Service: { Name: "datafsd", Type: "notify", Description: "Root VFS Mount" },
    Exec: {
        Path: "/System/rootfsd/init.lua",
        Arguments: ["--volume", "/dev/vol1", "--path", "/"],
        Blob: rootfsdBlob,
        // @ts-ignore
        Preload: package.preload
    },
    Dependencies: { Requires: ["datavold"], After: ["datavold"] }
});

// Run filesystem related services (stage 1)
ServiceRunner.run(mailbox);
print("Started ram daemons!");

// Run other services (stage 2)
ServiceRegistry.discover("/System/Config/Services");
ServiceRunner.run(mailbox);
print("Started other daemons!")

ReaperService.start();
proc.exit(0);