/** @noResolution */
declare module "libsystem.utils" {
    namespace utils {
        export type ArgumentType = "number" | "multiple" | "multiple number" | string | boolean;

        export interface ParsingArguments {
            /** * Whether to stop processing arguments when a positional argument is passed.
             * e.g., `myprog -s arg -i` will map `s = true`, but `-i` and anything after will be treated as positional.
             */
            stopProcessingOnPositionalArgument?: boolean,
        }

        /**
         * Creates a deep, by-value clone of a given table or object.
         * Recursively copies nested structures to ensure the returned object is
         * completely independent of the original memory reference.
         * @param obj The object, table, or array to be deeply copied.
         * @returns A completely distinct clone of the provided object.
         */
        export function deepcopy<T>(obj: T): T;

        /**
         * Takes a list of raw arguments and a schema, and returns an object with the
         * extracted arguments (and values if requested). If an argument with exactly `--`
         * is passed, processing of arguments stops, and all subsequent arguments are
         * added to the list as positional arguments.
         * @param args The raw arguments array as passed to the program.
         * @param schema A mapping that specifies how each argument is handled.
         * Single-character arguments are handled through `-a`, and longer arguments through `--argument`.
         * - If the value is `true` (or truthy), this argument requires a string parameter.
         * - If the value is `"number"`, the argument requires a number parameter.
         * - If the value is `"multiple"`, the argument can be specified multiple times and requires a string parameter. Returned in an array.
         * - If the value is `"multiple number"`, the argument can be specified multiple times and requires a number parameter. Returned in an array.
         * - If the value is `false`, the argument is a flag and does not take a parameter.
         * - If the value starts with `@`, the parameter is an alias and will be stored in that target argument instead.
         * @param opts Special configuration parameters for the parser.
         * @returns The parsed arguments as key-value entries, plus positional arguments as numeric array entries. Throws a ruthless error if arguments are invalid or missing.
         */
        export function parseArguments(args: string[], schema: Record<string, ArgumentType>, opts?: ParsingArguments): Record<string | number, boolean | string | string[]>;
    }

    export = utils;
}