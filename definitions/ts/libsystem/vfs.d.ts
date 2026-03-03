import {fs} from "libsystem.raw";

/** @noResolution */
declare module "libsystem.vfs" {
    namespace vfs {
        export interface UserContext {
            uid: number,
            gid: number,
            groups: number[],
        }

        export interface VFSHandlers {
            onOpen?: (path: string, mode: string, user: UserContext) => number;
            onClose?: (fileId: number) => void;
            onRead?: (fileId: number, bytes: number, offset: number, user: UserContext) => string;
            onWrite?: (fileId: number, data: string, offset: number, user: UserContext) => number;
            onStat?: (path: string, user: UserContext) => fs.FileMetadata;
            onList?: (path: string, user: UserContext) => string[];
            onMkdir?: (path: string, user: UserContext) => void;
            onRemove?: (path: string, user: UserContext) => void;
            onRename?: (path: string, destination: string, user: UserContext) => void;
            onCopy?: (path: string, destination: string, user: UserContext) => void;
            onSetattr?: (path: string, attr: fs.SettableAttributes, user: UserContext) => void;
            onIoctl?: (fileId: number, cmd: string, args: any[], user: UserContext) => any;
        }

        /** @customConstructor FileSystemServer.new */
        export class FileSystemServer {
            constructor(handlers: VFSHandlers)

            start(): void
            stop(): void
            getPortId(): PortId
        }
    }

    // @ts-ignore
    export = vfs;
}