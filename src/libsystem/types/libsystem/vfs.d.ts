import {fs} from "libsystem.raw";

/** @noResolution */
declare module "libsystem.vfs" {
    namespace vfs {
        export interface UserContext {
            uid: number,
            gid: number,
            groups: number[],
        }

        export interface IFileHandle {
            read?: (bytes: number, offset: number, user: UserContext) => string;
            write?: (data: string, offset: number, user: UserContext) => number;
            flush?: (user: UserContext) => void;
            ioctl?: (cmd: string, args: any[], user: UserContext) => any;
            close?: () => void;
        }

        export interface IVFSHandlers {
            onOpen?: (path: string, mode: string, user: UserContext) => IFileHandle;
            onStat?: (path: string, user: UserContext) => fs.FileMetadata;
            onList?: (path: string, user: UserContext) => string[];
            onMkdir?: (path: string, user: UserContext) => void;
            onRemove?: (path: string, user: UserContext) => void;
            onRename?: (path: string, destination: string, user: UserContext) => void;
            onCopy?: (path: string, destination: string, user: UserContext) => void;
            onSetattr?: (path: string, attr: fs.SettableAttributes, user: UserContext) => void;
        }

        /** @customConstructor FileSystemServer.new */
        export class FileSystemServer {
            constructor(handlers: IVFSHandlers)

            start(): void
            stop(): void
            getPortId(): PortId
        }
    }

    // @ts-ignore
    export = vfs;
}