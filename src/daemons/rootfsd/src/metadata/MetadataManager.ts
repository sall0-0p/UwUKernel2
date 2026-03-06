import {fs} from "libsystem.raw";

export interface StoredMetadata {
    uid: number,
    gid: number,
    created: number,
    modified: number,
    accessed: number,
    permissions: { // should be stored as octal
        user: { read: boolean, write: boolean, execute: boolean };
        group: { read: boolean, write: boolean, execute: boolean };
        other: { read: boolean, write: boolean, execute: boolean };
        setuid: boolean,
        setgid: boolean,
        sticky: boolean,
    },
}

export class MetadataManager {
    constructor(private volume: string) {

    }

    public saveMetadata(path: string, metadata: StoredMetadata) {

    }

    public loadMetadata(path: string): any {
        return {}
    }
}