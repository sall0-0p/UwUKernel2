/** @noResolution */
declare module "libsystem.raw" {
    /**
     * Inter-Process Communication (IPC) API
     * Provides message passing capabilities between processes via port kernel objects.
     */
    export namespace ipc {
        export interface SendOptions {
            /** A handle to send back to the receiver to allow them to reply */
            reply_port?: PortID;
            /** List of handles to move to the receiver. Kernel removes them from the caller and creates new handles in the receiver space. */
            transfer?: FileDescriptor[];
            /** Event type, used for routing and identification. Default is IPC */
            type?: string;
        }

        export interface ReceiveOptions {
            // Currently empty in implementation as kernel IPC receive does not utilize options yet.
        }

        export interface IpcMessage {
            /** Process ID of the sender */
            pid: ProcessID;
            /** ID of a handle to send a reply to, provides a temporary reply right */
            reply?: PortID;
            /** List of handles transferred from the sender */
            handles?: FileDescriptor[];
            /** The payload sent by the sender */
            data: any;
            /** Type of the IPC message */
            type: string;
        }

        export interface IpcStat {
            /** Number of messages currently waiting in the queue */
            messages: number;
            /** Maximum number of messages the queue can hold */
            capacity: number;
            /** Number of threads actively waiting to receive from this port */
            receivers: number;
            /** Number of processes that hold a send right to this port */
            senders: number;
        }

        /**
         * Creates a new port kernel object. The calling process receives a receive right.
         * @returns A file descriptor pointing to the created port.
         */
        export function create(): PortID;

        /**
         * Sends a message to a port. This is non-blocking unless the target queue is full.
         * @param port The file descriptor pointing to the target port.
         * @param msg The data payload to send.
         * @param opts Optional configuration for sending (transferring handles, reply ports, etc.).
         * @throws EBADF: Invalid file descriptor.
         * @throws EBADF: File descriptor is not a port right.
         * @throws EBADF: Invalid reply port
         * @throws EBADF: Trying to transfer invalid file descriptor.
         * @throws EINTERNAL: Right points to invalid port
         * @throws EPIPE: Attempt to write to port with no recipient.
         */
        export function send(port: PortID, msg: any, opts?: SendOptions): void;

        /**
         * Blocks until a message arrives on the specified port.
         * @param port The file descriptor pointing to the port.
         * @param opts Optional configuration for receiving.
         * @returns The received IPC message.
         * @throws EBADF: Invalid file descriptor.
         * @throws EPERM: Descriptor is not a receive right.
         * @throws EPERM: Only port owner can receive messages.
         */
        export function receive(port: PortID, opts?: ReceiveOptions): IpcMessage;

        /**
         * Releases a port handle.
         * @param port The handle to close.
         * @throws Invalid file descriptor
         */
        export function close(port: PortID): void;

        /**
         * Returns debug and statistical information about a port.
         * @param port The handle to inspect.
         * @returns An object containing the port's current status and capacity.
         * @throws EBADF: Invalid file descriptor.
         * @throws EBADF: File descriptor is not a port right.
         * @throws EINTERNAL: Right points to invalid port
         */
        export function stat(port: PortID): IpcStat;
    }
}