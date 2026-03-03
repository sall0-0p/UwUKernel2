/** @noResolution */
declare module "libsystem.toml" {
    namespace toml {
        export interface EncodeOptions {
            indent?: boolean,
        }

        export interface DecodeOptions {

        }

        /**
         * Encodes a table into TOML format. This table must only have integer or
         * string keys in itself and each subtable, and cannot mix strings and ints.
         * @param table The table to encode
         * @param opts Any options to specify while encoding
         */
        export function encode(table: object, opts?: EncodeOptions): string

        /**
         * Parses TOML data into a table.
         * @param str The TOML data to decode
         * @param opts Options (none available in this version)
         */
        export function decode(str: string, opts?: DecodeOptions): string
    }

    export = toml;
}