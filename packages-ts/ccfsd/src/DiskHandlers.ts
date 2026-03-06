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
}