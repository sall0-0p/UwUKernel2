import {IVFSHandlers, UserContext} from "libsystem.vfs";
import {fs} from "libsystem.raw";
import {DiskFile} from "./DiskFile";
import {CCHandle} from "./interfaces/CCHandles";

export class DiskHandlers implements IVFSHandlers {
    constructor(private device: FileDescriptor) {

    }

    onOpen(path: string, mode: fs.OpenMode, user: UserContext): DiskFile {
        if (user.uid != 0) error("EPERM: Permission denied.", 3);
        let handle: CCHandle;
        try {
            handle = fs.ioctl(this.device, "open", path, mode);
        } catch (e) {
            error("ELIMIT: Too many files open by the underlying system, change your CraftOS configuration.");
        }

        return new DiskFile(handle, mode);
    }

    onList(path: string, user: UserContext): string[] {
        if (path == "/" && user.uid != 0) {
            return [];
        } else if (path != "/" && user.uid != 0) {
            error("EPERM: Permission denied.", 3);
        }

        return fs.ioctl(this.device, "list", path);
    }

    onMkdir(path: string, user: UserContext): void {
        if (user.uid != 0) error("EPERM: Permission denied.", 3);
        fs.ioctl(this.device, "makeDir", path);
    }

    onRename(path: string, destination: string, user: UserContext): void {
        if (user.uid != 0) error("EPERM: Permission denied.", 3);
        fs.ioctl(this.device, "move", path, destination);
    }

    onRemove(path: string, user: UserContext): void {
        if (user.uid != 0) error("EPERM: Permission denied.", 3);
        fs.ioctl(this.device, "delete", path);
    }

    onCopy(path: string, destination: string, user: UserContext): void {
        if (user.uid != 0) error("EPERM: Permission denied.", 3);
        fs.ioctl(this.device, "copy", path, destination);
    }

    onStat(path: string, user: UserContext): fs.FileMetadata {
        if (user.uid != 0) error("EPERM: Permission denied.", 3);
        const attributes: { size: number, isDir: boolean, isReadOnly: boolean, created: number, modified: number } = fs.ioctl(this.device, "attributes", path);
        return {
            uid: 0,
            gid: 0,
            size: attributes.size,
            isDir: attributes.isDir,
            isLink: false,
            created: attributes.created,
            modified: attributes.modified,
            accessed: 0,
            permissions: {
                raw: 0o666,
                string: "rw-rw-rw-",
                user: { read: true, write: true, execute: false },
                group: { read: true, write: true, execute: false },
                other: { read: true, write: true, execute: false },
                setuid: false,
                setgid: false,
                sticky: false,
            }
        }
    }
}