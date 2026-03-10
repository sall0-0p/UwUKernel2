import {IFileHandle, UserContext} from "libsystem.vfs";
import {CCHandle, ReadHandle, WriteHandle} from "./interfaces/CCHandles";
import {fs} from "libsystem.raw";

export class DiskFile implements IFileHandle {
    constructor(
        private handle: CCHandle,
        private mode: fs.OpenMode
    ) {
    }

    public read(bytes: number, offset: number, user: UserContext): string {
        if (this.mode != "r") error("EINVAL: File has to be open in mode capable of reading.");
        this.handle.seek("set", offset);
        return (this.handle as ReadHandle).read(bytes) as string;
    }

    public write(data: string, offset: number, user: UserContext): number {
        if (this.mode != "w" && this.mode != "a") error("EINVAL: File has to be open in mode capable of writing.");
        this.handle.seek("set", offset);
        (this.handle as WriteHandle).write(data)
        return data.length;
    }

    public flush(user: UserContext): void {
        if (this.mode != "w" && this.mode != "a") error("EINVAL: File has to be open in mode capable of flushing.");
        (this.handle as WriteHandle).flush();
    }

    public close() {
        this.handle.close();
    }
}