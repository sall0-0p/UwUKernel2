declare type ProcessId = number & { readonly __brand: unique symbol };
declare type ThreadId = number & { readonly __brand: unique symbol };
declare type PortId = number & { readonly __brand: unique symbol };
declare type TimerId = number & { readonly __brand: unique symbol };
declare type FileDescriptor = number | PortId;

declare const _HOST: string;
declare const arg: string[];