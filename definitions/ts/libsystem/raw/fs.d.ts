/** @noResolution */
declare module "libsystem.raw" {
    /**
     * Filesystem API
     * Provides standard VFS (Virtual File System) interactions, handling files, directories, and mounts.
     */
    export namespace fs {
        export type OpenMode = "r" | "w" | "a" | "r+";

        export type SeekWhence = "set" | "cur" | "end" | 0 | 1 | 2;

        export interface PermissionBlock {
            read: boolean;
            write: boolean;
            execute: boolean;
        }

        export interface FilePermissions {
            raw: number;
            string: string;
            user: PermissionBlock;
            group: PermissionBlock;
            other: PermissionBlock;
            setuid: boolean;
            setgid: boolean;
            sticky: boolean;
        }

        export interface FileMetadata {
            uid: number;
            gid: number;
            size: number;
            isDir: boolean;
            isLink: boolean;
            created: number;
            modified: number;
            accessed: number;
            linkTarget?: string;
            permissions: FilePermissions;
        }

        export interface SettableAttributes {
            mode?: number;
            uid?: number;
            gid?: number;
            modified?: number;
            created?: number;
            accessed?: number;
        }

        /**
         * Opens a file or device.
         * @param path Absolute path to the file.
         * @param mode Mode to open the file in ("r", "w", "a", "r+").
         * @param opts Optional configuration table.
         * @returns File descriptor pointing to the opened file.
         * @throws EINVAL: Bad argument #1: Path must be a string.
         * @throws EINVAL: Bad argument #2: Mode must be a string.
         * @throws EINVAL: Bad argument #3: Opts must be a table or nil.
         * @throws ENOTFOUND: No mount point was resolved for this path.
         */
        export function open(path: string, mode: OpenMode, opts?: Record<string, any>): FileDescriptor;

        /**
         * Closes the file descriptor. Releases any locks.
         * (Note: While VFS expects an FD number, api/fs.lua incorrectly enforces a string assertion internally).
         * @param fd The file descriptor to close.
         * @throws EINVAL: Bad argument #1: Path must be a string.
         * @throws EBADF: Invalid file descriptor.
         */
        export function close(fd: FileDescriptor): void;

        /**
         * Reads data from the file.
         * @param fd The file descriptor.
         * @param count Number of bytes to read.
         * @param offset Optional offset for an absolute read (pread).
         * @returns The read string, or undefined if EOF is reached.
         * @throws EINVAL: Bad argument #1: File descriptor must be a number.
         * @throws EINVAL: Bad argument #2: Number of bytes must be a number (obviously).
         * @throws EINVAL: Bad argument #3: Offset must be a number or nil.
         * @throws EBADF: Invalid file descriptor.
         * @throws EINVAL: Object does not support reading
         */
        export function read(fd: FileDescriptor, count: number, offset?: number): string | undefined;

        /**
         * Writes data to a file.
         * @param fd The file descriptor.
         * @param data The string or data payload to write.
         * @param offset Optional offset for an absolute write (pwrite).
         * @returns Number of bytes written.
         * @throws EINVAL: Bad argument #1: File descriptor must be a number.
         * @throws EINVAL: Bad argument #2: Data written must not be nil!
         * @throws EINVAL: Bad argument #3: Offset must be a number or nil.
         * @throws EBADF: Invalid file descriptor.
         * @throws EINVAL: Object does not support writing
         */
        export function write(fd: FileDescriptor, data: any, offset?: number): number;

        /**
         * Moves the file cursor.
         * @param fd The file descriptor.
         * @param offset Number of bytes to move.
         * @param whence Position to base the move on ("set" / 0, "cur" / 1, "end" / 2).
         * @returns The new absolute position.
         * @throws EINVAL: Bad argument #1: File descriptor must be a number.
         * @throws EINVAL: Bad argument #2: Offset must be a number.
         * @throws EINVAL: Bad argument #3: Whence must be either number, string, or nil.
         * @throws EBADF: Invalid file descriptor.
         * @throws EBADF: Not a file.
         * @throws EINVAL: Invalid whence mode
         */
        export function seek(fd: FileDescriptor, offset: number, whence?: SeekWhence): number;

        /**
         * Retrieves metadata about a file or directory.
         * @param path Path to the file or directory.
         * @param opts Optional configuration table.
         * @returns The file metadata.
         * @throws EINVAL: Bad argument #1: Path must be a string.
         * @throws EINVAL: Bad argument #2: Opts must be a table or nil.
         * @throws ENOTFOUND: No mount point was resolved for this path.
         */
        export function stat(path: string, opts?: Record<string, any>): FileMetadata;

        /**
         * Lists entries in a directory.
         * @param path Directory path.
         * @returns Array of filenames within the directory.
         * @throws EINVAL: Bad argument #1: Path must be a string.
         * @throws ENOTFOUND: No mount point was resolved for this path.
         */
        export function list(path: string): string[];

        /**
         * Sends a raw command to the underlying driver.
         * @param fd Handle to the device.
         * @param cmd Driver-specific command.
         * @param args Variable arguments passed to the driver.
         * @returns Values returned by the driver.
         * @throws EINVAL: Bad argument #1: File descriptor must be a number.
         * @throws EINVAL: Bad argument #2: Command must be a string.
         * @throws EBADF: Invalid file descriptor.
         * @throws EINVAL: Object does not support ioctl
         */
        export function ioctl(fd: FileDescriptor, cmd: string, ...args: any[]): any;

        /**
         * Mounts a filesystem driver to a specific path.
         * Requires root permissions.
         * @param path Directory to be mounted.
         * @param port IPC handle of the driver process.
         * @throws EINVAL: Bad argument #1: Path must be a string.
         * @throws EINVAL: Bad argument #2: EINVAL: Bad argument #1: File descriptor must be a number.
         * @throws EPERM: Only root can mount filesystems.
         * @throws EBADF: Invalid port handle.
         * @throws EBADF: Handle must be a port.
         * @throws EBUSY: Path is already a mount point.
         */
        export function mount(path: string, port: PortID): void;

        /**
         * Unmounts a filesystem driver from a specific path.
         * Requires root permissions or matching owner UID.
         * @param path Absolute path to unmount.
         * @throws EINVAL: Bad argument #1: Path must be a string.
         * @throws EINVAL: Path is not a mount point.
         * @throws EPERM: Permission denied.
         */
        export function unmount(path: string): void;

        /**
         * Changes the metadata attributes of a file or directory.
         * Exposed as `setattr` mapping to syscall `fs.setaddr`.
         * @param path Path to the file or directory.
         * @param attr Attributes object containing properties to modify.
         * @throws EINVAL: Bad argument #1: Path must be a string.
         * @throws EINVAL: Bad argument #2: Attributes must be table.
         * @throws ENOTFOUND: No mount point was resolved for this path.
         */
        export function setattr(path: string, attr: SettableAttributes): void;

        /**
         * Moves or renames a file.
         * @param path Path to the file to be moved.
         * @param destination Destination path.
         * @throws EINVAL: Bad argument #1: Path must be a string.
         * @throws EINVAL: Bad argument #1: Destination must be a string.
         * @throws ENOTFOUND: No mount point was resolved for this path.
         */
        export function rename(path: string, destination: string): void;

        /**
         * Copies a file to a new destination.
         * @param path Path to the file to be copied.
         * @param destination Destination path.
         * @throws EINVAL: Bad argument #1: Path must be a string.
         * @throws EINVAL: Bad argument #1: Destination must be a string.
         * @throws ENOTFOUND: No mount point was resolved for this path.
         */
        export function copy(path: string, destination: string): void;

        /**
         * Removes a file or directory.
         * @param path Path to the file or directory to remove.
         * @throws EINVAL: Bad argument #1: Path must be a string.
         * @throws ENOTFOUND: No mount point was resolved for this path.
         */
        export function remove(path: string): void;

        /**
         * Creates a directory at the specified path.
         * @param path Path to the new directory.
         * @throws EINVAL: Bad argument #1: Path must be a string.
         * @throws ENOTFOUND: No mount point was resolved for this path.
         */
        export function mkdir(path: string): void;
    }
}