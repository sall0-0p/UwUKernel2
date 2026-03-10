/** @noResolution */
declare module "libsystem.raw" {
    /**
     * Process & Task Management API
     * Provides low-level control over process spawning, termination, attributes, and signaling.
     */
    export namespace proc {
        /**
         * Identifiers for strictly limited process resources.
         */
        export type ProcessLimitResource = "maxThreads" | "maxProcesses" | "maxFiles" | "maxPorts";

        export const enum Signal {
            SIGHUP = 1,
            SIGINT = 2,
            SIGKILL = 9,
            SIGPIPE = 13,
            SIGTERM = 15,
            SIGCHLD = 17,
        }

        export interface ProcessLimits {
            maxThreads: number;
            maxProcesses: number;
            maxFiles: number;
            maxPorts: number;
        }

        export interface ShareProperties {
            fd: number,
            op: "SHARE" | "MOVE",
        }

        export type FileDescriptorTable = Record<number, FileDescriptor | ShareProperties>;

        export interface SpawnAttributes {
            /** Map of environment variables to pass to the process */
            env?: Record<string, string>;
            /** Working directory path */
            cwd?: string;
            /** Map of child file descriptors to parent file descriptors */
            fds?: FileDescriptorTable
            /** Run as user ID (requires root) */
            uid?: number;
            /** Run as group ID (requires root) */
            gid?: number;
            /** Run with supplementary group IDs (requires root) */
            groups?: number[];
            /** Debug name for process list */
            name?: string;
            /** Strict limits applied to the process */
            limits?: Partial<ProcessLimits>;
            /** Lua source code to run from instead of reading from `path` */
            blob?: string;
            /** Injects into `package.preload` of a child process environment */
            preload?: Record<string, any>;
            /** Sets parent of process, only root */
            parent?: ProcessId,
        }

        export interface WaitReturns {
            /** Process ID of the child that exited */
            pid: ProcessId;
            /** Exit status code */
            code: number;
            /** CPU time used by the exited process */
            usage: number;
        }

        export interface ProcessInfo {
            pid: ProcessId;
            ppid: ProcessId;
            uid: number;
            gid: number;
            state: "ALIVE" | "ZOMBIE" | "STOPPED" | "DEAD";
            groups: number[];
            name: string;
            cpuTime: number;
            children: ProcessId[];
            limits: ProcessLimits;
        }

        export interface SettableAttributes {
            /** Change user id (root-only) */
            uid?: number;
            /** Change group id (root-only) */
            gid?: number;
            /** Set supplementary groups (root-only) */
            groups?: number[];
            /** Change current working directory */
            cwd?: string;
        }

        /**
         * Creates a new process in one atomic method. Analogue of `posix_spawn`.
         * @param path Path to the executable (Lua).
         * @param args Array of arguments.
         * @param attributes Optional process creation attributes.
         * @returns PID of the newly created process.
         * @throws EINVAL: Bad argument #1: Path must be a string.
         * @throws EINVAL: Bad argument #2: Arguments must be nil or table.
         * @throws EINVAL: Bad argument #2: Attributes must be nil or table.
         * @throws EPERM: No permission. (If trying to change UID/GID/Groups/Limits without root permissions)
         * @throws ESRSH: Invalid parent.
         * @throws ENOENT: Executable not found: <path>`
         * @throws ENOEXEC: Syntax error: <error>`
         * @throws EBADF: Parent handle <fd> is invalid`
         */
        export function spawn(path: string, args?: string[], attributes?: SpawnAttributes): ProcessId;

        /**
         * Terminates the calling process. Closes all owned handles/ports.
         * @param code Exit status (0 = success, >0 = error).
         * @throws EINVAL: Bad argument #1: Code must be an integer.
         * @throws ESRSH: Process not found.
         */
        export function exit(code: number): void;

        /**
         * Blocks until a child process exits.
         * @param pid PID of the child to wait for, or `-1` to wait for any child.
         * @returns Information regarding the exited child.
         * @throws EINVAL: Bad argument #1: Pid must be a valid number.
         * @throws EINVAL: Bad argument #2: Options must be table or nil.
         * @throws ECHILD: No child processes.
         * @throws ECHILD: PID <pid> is not a child of this process.
         */
        export function wait(pid: ProcessId | -1, opts?: Record<string, never>): WaitReturns;

        /**
         * Sends a control signal to the target process.
         * @param pid Process to send the signal to.
         * @param signal ID of the desired signal to send.
         * @throws EINVAL: Bad argument #1: Pid must be a valid number.
         * @throws EINVAL: Bad argument #2: Signal ID must be a number.
         * @throws ESRCH: Process not found.
         * @throws EPERM: No permission.
         * @throws EINVAL: Invalid signal!`
         */
        export function kill(pid: ProcessId, signal: Signal): void;

        /**
         * Returns metadata of a running process.
         * @param pid PID of the process to get metadata of (defaults to calling process if omitted).
         * @returns Metadata of the requested process.
         * @throws ESRCH: Process not found.
         */
        export function info(pid?: ProcessId): ProcessInfo;

        /**
         * Changes attributes of the running process.
         * @param attr Attributes to modify (uid, gid, groups, cwd).
         * @throws EPERM: No permission. (If trying to alter UID, GID, or Groups without root)
         */
        export function setattr(attr: SettableAttributes): void;

        /**
         * Sets strict limits for the calling process (inherited by children).
         * Limits cannot be raised without root permissions, but can be decreased at will.
         * @param resource The type of limit to enforce.
         * @param value The maximum integer capacity allowed for the resource.
         * @throws EINVAL: Bad argument #1: Invalid resource.
         * @throws EINVAL: Bad argument #2: Value must be a number.
         * @throws EINVAL: Bad argument #2: Value must be positive.
         * @throws EPERM: No permission. (If raising a limit without root)
         */
        export function limit(resource: ProcessLimitResource, value: number): void;

        /**
         * Retrieves a list of all active process IDs in the system.
         * @returns An array of active process PIDs.
         */
        export function list(): ProcessId[];
    }
}