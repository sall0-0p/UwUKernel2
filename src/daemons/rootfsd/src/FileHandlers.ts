import {IFileHandle, IVFSHandlers, UserContext} from "libsystem.vfs";
import {FileHandle} from "./FileHandle";
import {MetadataManager} from "./metadata/MetadataManager";
import {fs} from "libsystem.raw";

export class FileHandlers implements IVFSHandlers {
    private metadataManager: MetadataManager;
    constructor(private volume: string) {
        this.metadataManager = new MetadataManager(volume);
    }

    onOpen(path: string, mode: string, user: UserContext): IFileHandle {
        // TODO: Add permission checks

        const fd = fs.open(this.volume + path, mode as fs.OpenMode);
        return new FileHandle(this.volume, fd, mode);
    }

    onList(path: string, user: UserContext): string[] {
        // TODO: Add permission checks
        // TODO: Hide metadata file

        return fs.list(this.volume + path);
    }

    onMkdir(path: string, user: UserContext) {
        // TODO: Add permission checks
        // TODO: Check if there is already existing file for that
        print(this.volume, path, this.volume + path);
        fs.mkdir(this.volume + path);
    }

    onRename(path: string, destination: string, user: UserContext) {
        // TODO: Add permission checks
        // TODO: Check if there is already existing file at destination

        fs.rename(this.volume + path, destination);
    }

    onRemove(path: string, user: UserContext) {
        // TODO: Add permission checks
        // TODO: Check if not root

        fs.remove(this.volume + path);
    }

    onCopy(path: string, destination: string, user: UserContext) {
        // TODO: Add permission checks
        // TODO: Check if there is already existing file at destination

        fs.copy(this.volume + path, destination);
    }

    onSetattr(path: string, attr: fs.SettableAttributes, user: UserContext) {
        // TODO: Add permission checks
        // TODO: Update attributes
    }

    onStat(path: string): fs.FileMetadata {
        // TODO: Add permission checks
        // TODO: Check attributes
        const blockMeta = fs.stat(this.volume + path);
        return {
            uid: 0,
            gid: 0,
            size: blockMeta.size,
            isDir: blockMeta.isDir,
            isLink: false,
            created: blockMeta.created,
            modified: blockMeta.modified,
            accessed: blockMeta.accessed,
            permissions: {
                raw: 0o774,
                string: "rw-rw-r--",
                user: { read: true, write: true, execute: true },
                group: { read: true, write: true, execute: true },
                other: { read: true, write: false, execute: false },
                setuid: false,
                setgid: false,
                sticky: false,
            }
        };
    }
}

