import {IFileHandle, UserContext} from "libsystem.vfs";
import {fs} from "libsystem.raw";

export class FileHandle implements IFileHandle {
    constructor(private volume: string, private fd: number, private mode: string) {
    }

    read(bytes: number, offset: number, user: UserContext): string {
        if (this.mode != "r") error("EINVAL: File has to be open in mode capable of reading.");
        return fs.read(this.fd, bytes, offset);
    }

    write(data: string, offset: number, user: UserContext): number {
        if (this.mode != "w" && this.mode != "a") error("EINVAL: File has to be open in mode capable of reading.");
        return fs.write(this.fd, data, offset);
    }

    close() {
        fs.close(this.fd);
    }
}