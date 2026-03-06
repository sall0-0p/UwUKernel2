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

        fs.rename(path, destination);
    }

    onRemove(path: string, user: UserContext) {
        // TODO: Add permission checks
        // TODO: Check if not root

        fs.remove(path);
    }

    onCopy(path: string, destination: string, user: UserContext) {
        // TODO: Add permission checks
        // TODO: Check if there is already existing file at destination

        fs.copy(path, destination);
    }

    onSetattr(path: string, attr: fs.SettableAttributes, user: UserContext) {
        // TODO: Add permission checks
        // TODO: Update attributes
    }

    onStat(path: string): fs.FileMetadata {
        // TODO: Add permission checks
        // TODO: Check attributes
        return {} as unknown as fs.FileMetadata;
    }
}

