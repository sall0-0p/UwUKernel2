declare type ProcessID = number & { readonly __brand: unique symbol };
declare type ThreadID = number & { readonly __brand: unique symbol };
declare type FileDescriptor = number & { readonly __brand: unique symbol };
declare type PortID = number & { readonly __brand: unique symbol };
declare type TimerID = number & { readonly __brand: unique symbol };