import * as task from "task";
import * as proc from "proc";
task.create(() => {
    while (true) {
        // I want to crash your system!
    }
})

task.create(() => {
    let i = 0;
    while (i < 20) {
        print("*");
        i++;
    }
})

task.create(() => {
    let i = 0;
    while (i < 20) {
        print("-");
        i++;
    }
})

print(task.list());
proc.exit(0);