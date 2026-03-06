export type CCHandle = ReadHandle | WriteHandle | ReadWriteHandle;

/**
 * A file handle opened for reading.
 * Returned by fs.open using "r" or "rb".
 */
/** @noSelf */
export interface ReadHandle {
    /**
     * Reads a line of text from the file.
     * @param withTrailing Whether to include the trailing newline character.
     * @returns The read line, or undefined if at the end of the file.
     */
    readLine(withTrailing?: boolean): string | undefined;

    /**
     * Reads the remainder of the file.
     * @returns The remaining file contents, or undefined if at the end of the file.
     */
    readAll(): string | undefined;

    /**
     * Reads a specific number of characters (text mode) or a single byte (binary mode).
     * @param count The number of characters to read.
     * @returns The read data, or undefined if at the end of the file.
     */
    read(count?: number): string | number | undefined;

    /**
     * Seeks to a new position within the file.
     * @param whence Where the offset is relative to ("set", "cur", or "end"). Defaults to "cur".
     * @param offset The offset to seek to. Defaults to 0.
     * @returns The new position in the file.
     */
    seek(whence?: "set" | "cur" | "end", offset?: number): number;

    /** * Closes the file handle, freeing it for use by other programs.
     */
    close(): void;
}

/**
 * A file handle opened for writing or appending.
 * Returned by fs.open using "w", "a", "wb", or "ab".
 */
/** @noSelf */
export interface WriteHandle {
    /**
     * Writes text (text mode) or a byte (binary mode) to the file.
     * @param value The text or byte to write.
     */
    write(value: string | number): void;

    /**
     * Writes a line of text to the file, appending a newline.
     * @param value The text to write.
     */
    writeLine(value: string): void;

    /**
     * Seeks to a new position within the file.
     * @param whence Where the offset is relative to ("set", "cur", or "end"). Defaults to "cur".
     * @param offset The offset to seek to. Defaults to 0.
     * @returns The new position in the file.
     */
    seek(whence?: "set" | "cur" | "end", offset?: number): number;

    /** * Saves the current file contents to disk without closing the handle.
     */
    flush(): void;

    /** * Closes the file handle, saving any unwritten changes.
     */
    close(): void;
}

/**
 * A file handle opened for both reading and writing (update mode).
 * Returned by fs.open using "r+", "w+", "rb+", or "wb+".
 */
/** @noSelf */
export interface ReadWriteHandle extends ReadHandle, WriteHandle {
    // Inherits all reading, writing, seeking, flushing, and closing methods.
}