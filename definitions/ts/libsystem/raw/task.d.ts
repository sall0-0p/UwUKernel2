/** @noResolution */
declare module "libsystem.raw" {
    /**
     * Task (Thread) Management API
     * Provides control over threads (coroutines) within the current process.
     */
    export namespace task {
        /**
         * Creates a new thread (coroutine) within the current process.
         * @param entry The Lua function to execute.
         * @param args Optional array of arguments to pass to the entry function.
         * @returns The unique thread ID (TID) of the new thread.
         * @throws ESRCH: Process not found
         */
        export function create(entry: (...args: any[]) => any, args?: any[]): ThreadID;

        /**
         * Blocks the calling thread until the target thread terminates.
         * @param tid The ID of the thread to wait for.
         * @returns A tuple where the first element is a boolean indicating success (true if normal exit, false if crashed), followed by the thread's return values or error message.
         * @throws ESRCH: Thread not found
         * @throws EDEADLK: Cannot join self
         */
        export function join(tid: ThreadID): [boolean, ...any[]];

        /**
         * Gets the thread ID of the currently running thread.
         * @returns The current thread ID.
         */
        export function id(): ThreadID;

        /**
         * Gets a list of all thread IDs belonging to the current process.
         * @returns An array of active thread IDs.
         */
        export function list(): ThreadID[];
    }
}