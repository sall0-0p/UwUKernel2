/**
 * Device API
 * Provides interaction with physical peripherals and virtual devices.
 */
/** @noResolution */
declare module "dev" {
    /**
     * Wraps a native ComputerCraft peripheral or virtual device into a kernel handle.
     * @param name The network or side name of a peripheral.
     * @returns An ID of a handle pointing to the native device.
     * @throws EINVAL: Bad argument #1: Name must be a string.
     * @throws ENOENT: Device not found: <name>
     * @throws EBUSY: Device is claimed by PID <pid>
     */
    export function open(name: string): FileDescriptor;

    /**
     * Returns a list of all attached peripheral names.
     * @returns An array of device names.
     */
    export function list(): string[];

    /**
     * Returns the type of the attached peripheral.
     * @param name The name of the peripheral.
     * @returns The type string of the device, or undefined if the device does not exist.
     */
    export function type(name: string): string | undefined;

    /**
     * Returns the list of methods available on the peripheral.
     * @param name The name of the peripheral.
     * @returns An array of available method names.
     */
    export function methods(name: string): string[];
}