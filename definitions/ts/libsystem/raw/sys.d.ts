/** @noResolution */
declare module "libsystem.raw" {
    /**
     * System API
     * Provides access to hardware timers, epoch timestamps, logging, and global system events.
     */
    export namespace sys {
        export type EpochLocale = "ingame" | "utc" | "local";

        export const enum Signal {
            SIGHUP = 1,
            SIGINT = 2,
            SIGKILL = 9,
            SIGPIPE = 13,
            SIGTERM = 15,
            SIGCHLD = 17,
        }

        export interface SystemInfo {
            /** OS version */
            version: string;
            /** Native ComputerCraft version */
            craftos_version: string;
            /** Host environment string */
            host: string;
            /** OS build number */
            build: number;
            /** Time since computer was started */
            uptime: number;
            /** Time since scheduler started running */
            startEpoch: number;
            /** Time spent running user processes */
            runningTime: number;
            /** Time spent running syscalls (kernel time) */
            systemTime: number;
            /** Time spent waiting for hardware events */
            idleTime: number;
        }

        /**
         * Returns the number of milliseconds since an epoch depending on the locale.
         * @param locale Locale to get the time for ("ingame", "utc", or "local").
         * @returns Milliseconds since the epoch.
         * @throws EINVAL: Bad argument #1: Locale must be string.
         */
        export function epoch(locale: EpochLocale): number;

        /**
         * Starts a system timer that fires after a duration in seconds.
         * @param port File descriptor pointing to the port that should receive the timer event.
         * @param duration Duration in seconds until the timer fires.
         * @param cookie Optional payload attached to the timer event.
         * @returns A unique timer ID used for cancellation.
         * @throws EINVAL: Bad argument #1: File descriptor must be a number.
         * @throws EINVAL: Bad argument #2: Duration must be a number.
         * @throws EINVAL: Bad argument #2: Duration must be positive number.
         * @throws EBADF: Invalid file descriptor.
         * @throws EBADF: File descriptor is not a port right.
         */
        export function timer(port: PortID, duration: number, cookie?: any): TimerID;

        /**
         * Sets an alarm for a specific in-game time (0.0 to 24.0).
         * @param port File descriptor pointing to the port that should receive the alarm event.
         * @param time Time for the alarm to be set to.
         * @param cookie Optional payload attached to the alarm event.
         * @returns A unique alarm ID used for cancellation.
         * @throws EINVAL: Bad argument #1: File descriptor must be a number.
         * @throws EINVAL: Bad argument #2: Time must be a number.
         * @throws EINVAL: Bad argument #2: Time must be positive number.
         * @throws EBADF: Invalid file descriptor.
         * @throws EBADF: File descriptor is not a port right.
         */
        export function alarm(port: PortID, time: number, cookie?: any): TimerID;

        /**
         * Cancels a timer or alarm based on its ID.
         * @param id The ID of the timer or alarm to cancel.
         * @throws EINVAL: Bad argument #1: Id must be a number.
         */
        export function cancel(id: TimerID): void;

        /**
         * Writes a message to the kernel ring buffer.
         * @param level Log severity ("INFO", "WARN", "ERROR").
         * @param msg The message content.
         */
        export function log(level: string, msg: string): void;

        /**
         * Returns an object containing global system information and resource usage.
         * @returns System information object.
         */
        export function info(): SystemInfo;

        /**
         * Subscribes a port to a specific raw ComputerCraft event type.
         * Once bound, the kernel intercepts all events of this type and routes them exclusively to the specified port.
         * Requires root permissions.
         * @param event The event name to bind.
         * @param port The file descriptor pointing to the port to receive events.
         * @throws EBADF: Invalid file descriptor.
         * @throws EPERM: Descriptor is not a receive right.
         * @throws ESMTH: Someone is already bound to this event!
         */
        export function bind_event(event: string, port: PortID): void;

        /**
         * Releases the exclusive subscription for an event type.
         * Requires root permissions.
         * @param event The event name to unbind.
         * @throws EPERM: No permission.
         */
        export function unbind_event(event: string): void;

        /**
         * Shuts down the computer.
         * Requires root permissions.
         * @throws EPERM: No permission.
         */
        export function shutdown(): void;

        /**
         * Reboots the computer.
         * Requires root permissions.
         * @throws EPERM: No permission.
         */
        export function reboot(): void;

        /**
         * Asks the system to send signals with this ID to the respective port, overriding default behavior.
         * @param signal The ID of the signal to override.
         * @param port The file descriptor pointing to a port. If omitted or undefined, unregisters the handler.
         * @throws EINVAL: Bad argument #1: Signal id must be a number.
         * @throws EINVAL: Bad argument #2: File descriptor must be a number.
         * @throws EBADF: Invalid file descriptor.
         * @throws EPERM: Descriptor is not a receive right.
         */
        export function signal(signal: Signal, port?: PortID): void;
    }
}