import {fs, proc} from "libsystem.raw";

interface UserCredentials {
    uid: number,
    gid: number,
    groups: number[]
}

export namespace ExecutionService {
    function checkPermissions(user: UserCredentials, metadata: fs.FileMetadata, op: "read" | "write" | "execute") {
        if (user.uid === 0) {
            if (op === "execute") {
                return metadata.permissions.user.execute ||
                    metadata.permissions.group.execute ||
                    metadata.permissions.other.execute;
            }
            return true;
        }

        if (user.uid === metadata.uid) {
            return metadata.permissions.user[op];
        }

        if (user.gid === metadata.gid || user.groups.includes(metadata.gid)) {
            return metadata.permissions.group[op];
        }

        return metadata.permissions.other[op];
    }

    export function execute(
        parent: number,
        path: string,
        args: string[],
        user: UserCredentials,
        opts?: proc.SpawnAttributes
    ): number {
        const stat = fs.stat(path);
        if (!stat) error("File does not exist!");
        if (!checkPermissions(user, stat, "execute")) error("No permission!");

        const file = fs.open(path, "r");
        const blob = fs.read(file, 2147483647);
        fs.close(file);

        opts.blob = blob;
        opts.parent = parent as ProcessId;
        opts.uid = stat.permissions.setuid ? stat.uid : user.uid;
        opts.gid = stat.permissions.setgid ? stat.gid : user.gid;
        // I forgot what sticky does
        // TODO: Implement sticky
        return proc.spawn(path, args, opts);
    }
}
