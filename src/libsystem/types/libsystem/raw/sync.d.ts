/** @noResolution */
declare module "libsystem.raw" {
    /**
     * Synchronization API
     * Provides kernel-level synchronization primitives: Mutex, Semaphore, and Condition Variable.
     */
    export namespace sync {
        export type SyncType = "MUTEX" | "SEM" | "COND";

        /**
         * Creates a new kernel synchronization object.
         * @param type The type of primitive to create ("MUTEX", "SEM", or "COND").
         * @param init Optional initial value. For MUTEX: 1 (unlocked) or 0 (locked by creator). For SEM: initial counter. Ignored for COND.
         * @returns A unique handle for the synchronization object.
         * @throws EINVAL: Invalid type specified.
         * @throws ELIMIT: Process handle limit reached.
         */
        export function create(type: SyncType, init?: number): SyncHandle;

        /**
         * Acquires a lock (Mutex) or decrements the counter (Semaphore).
         * If the object is busy, the calling thread is blocked until it becomes available or the timeout expires.
         * @param handle The synchronization object handle.
         * @param timeout Optional maximum wait time in seconds. `undefined` to wait forever, `0` for TryLock (returns immediately).
         * @returns `true` if acquired, `false` if the timeout occurred.
         * @throws EBADF: Invalid handle.
         * @throws EDEADLK: Attempting to lock a mutex you already hold.
         */
        export function lock(handle: SyncHandle, timeout?: number): boolean;

        /**
         * Releases a lock (Mutex) or increments the counter (Semaphore).
         * If other threads are waiting on this object, the next thread in the queue is woken up.
         * @param handle The synchronization object handle.
         * @throws EBADF: Invalid handle.
         * @throws EPERM: Attempting to unlock a mutex you do not own.
         */
        export function unlock(handle: SyncHandle): void;

        /**
         * Atomically releases the attached mutex and blocks execution on the condition variable.
         * When the thread wakes up, it automatically re-acquires the mutex before returning.
         * @param cond Handle to the Condition Variable.
         * @param mutex Handle to the Mutex currently held by the caller.
         * @param timeout Optional maximum wait time in seconds.
         * @returns `true` if signaled via notify, `false` if timeout occurred.
         * @throws EBADF: Invalid handles.
         * @throws EINVAL: Handles are not correct types.
         * @throws EPERM: Caller does not hold the mutex.
         */
        export function wait(cond: SyncHandle, mutex: SyncHandle, timeout?: number): boolean;

        /**
         * Wakes up threads that are sleeping on the specified condition variable.
         * @param cond Handle to the Condition Variable.
         * @param all Optional. `false` or omitted to wake one thread. `true` to wake all waiting threads (Broadcast).
         * @throws EBADF: Invalid handle.
         * @throws EINVAL: Handle is not a Condition Variable.
         */
        export function notify(cond: SyncHandle, all?: boolean): void;
    }
}