## Launchd communication protocol

### Starting service
```ts
// Starting pre defined service
interface LaunchctlRequest {
    type: "launchctl_start" | "launchctl_stop" | "launchctl_restart" | "launchctl_list" | "launchctl_reload",
    payload: {
        service?: string, // for start, stop, restart
    }
}

interface LaunchctlResponse {
    type: "launchctl_start" | "launchctl_stop" | "launchctl_restart" | "launchctl_list" | "launchctl_reload",
    payload: {
        success: boolean,
        error?: string,
        data?: any,
    }
}

interface SpawnRequest {
    type: "launchd_spawn",
}

interface SpawnResponse {
    type: "launchd_spawn",
    payload: {
        success: boolean,
        error?: string,
        pid?: number
    }
}

interface DiscoveryRequest {
    type: "service_discover",
    payload: {
        service: string
    }
}

interface DiscoveryResponse {
    type: "service_discover",
    payload: {
        success: boolean,
        error?: string,
    },
    handles?: number[],
}
```