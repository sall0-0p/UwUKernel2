import {proc, task} from "libsystem.raw";

export namespace ReaperService {
    function reap() {
        while (true) {
            const exited = proc.wait(-1);
            print(`Process ${exited.pid} exited with code ${exited.code}`);
        }
    }

    export function start() {
        const tid = task.create(() => reap());
        task.join(tid);
    }
}