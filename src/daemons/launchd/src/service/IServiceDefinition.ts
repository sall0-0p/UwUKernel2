export interface IServiceBlock {
    Name: string,
    Type?: "simple" | "notify",
    Description?: string,
}

export interface IExecBlock {
    Path: string,
    WorkingDir?: string,
    Arguments?: string[],
    Blob?: string,
    Preload?: Record<string, any>,
}

export interface ILimitsBlock {
    MaxPorts?: number
    MaxThreads?: number
    MaxProcesses?: number
    MaxFiles?: number
}

export interface IUserBlock {
    User?: number,
    Group?: number
}

export interface IRestartBlock {
    Policy?: "no" | "on-failure" | "always",
    Delay?: number,
}

export interface IActivationBlock {
    Enabled?: boolean,
    MountPoint?: string,
}

export interface IDependenciesBlock {
    Requires?: string[],
    Wants?: string[],
    After?: string[],
    Before?: string[],
}

export interface IServiceDefinition {
    Service: IServiceBlock,
    Exec: IExecBlock,
    Limits?: ILimitsBlock,
    User?: IUserBlock,
    Environment?: Record<string, string>,
    Restart?: IRestartBlock,
    Activation?: IActivationBlock,
    Dependencies?: IDependenciesBlock,
}