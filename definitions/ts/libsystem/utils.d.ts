/** @noResolution */
declare module "libsystem.utils" {
    namespace utils {
        export type ArgumentType = "number" | "multiple" | "multiple number" | string | boolean;
        export interface ParsingArguments {
            stopProcessingOnPositionalArgument?: boolean,
        }
        export function parseArguments(arguments: string[], schema: Record<string, ArgumentType>, opts?: ParsingArguments): Record<string | number, boolean | string | string[]>;
    }

    export = utils;
}