import {UserContext, VFSHandlers} from "libsystem.vfs";

export class DiskHandlers implements VFSHandlers {
    constructor(volume: string) {

    }

    onList(path: string, user: UserContext): string[] {
        return [ "go", "fuck", "yourself" ];
    }
}