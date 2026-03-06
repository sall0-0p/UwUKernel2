/** @noResolution */
declare module "libsystem.raw" {
    /**
     * IO API
     * Provides control over standard file descriptors and piping mechanisms.
     */
    export namespace io {
        /**
         * Duplicates a file descriptor.
         * @param oldFd File descriptor to copy.
         * @param newFd Optional specific file descriptor to duplicate to (overwrites if it exists).
         * @returns The file descriptor ID of the duplicate.
         * @throws EINVAL: Old FD must be a number
         * @throws EINVAL: New FD must be a number or nil
         * @throws EBADF: Invalid file descriptor <oldFd>
         * @throws EINTERNAL: PCB handle points to non-existent object
         */
        export function dup(oldFd: FileDescriptor, newFd?: number | FileDescriptor): FileDescriptor;

        /**
         * Creates a unidirectional byte stream.
         * Data written to the write part can be read from the read part.
         * (Note: Registered in syscall dispatcher but currently lacks backend implementation).
         * @returns A tuple where the first element is the read FD, and the second is the write FD.
         */
        export function pipe(): [FileDescriptor, FileDescriptor];
    }
}