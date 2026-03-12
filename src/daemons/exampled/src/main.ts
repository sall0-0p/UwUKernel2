import { sync, task, ipc, sys } from "libsystem.raw";

// Helper function to sleep without burning CPU, using standard kernel IPC and Timers
function sleep(seconds: number): void {
    const timerPort = ipc.create();
    sys.timer(timerPort, seconds);
    ipc.receive(timerPort);
    ipc.close(timerPort);
}

print("=== Starting Sync Primitive Test ===");

// 1. Create the synchronization primitives
const stateMutex = sync.create("MUTEX");
const stageCond = sync.create("COND");

// Shared state between threads
let counter = 0;
const TARGET_VALUE = 5;

// 2. The Waiter (Consumer Thread)
const consumerTid = task.create(() => {
    print("[Consumer] Starting up. Attempting to lock stateMutex...");

    sync.lock(stateMutex);
    print("[Consumer] Mutex locked. Entering condition check loop.");

    // The essential while loop to prevent spurious wakeups and race conditions
    while (counter < TARGET_VALUE) {
        print(`[Consumer] Counter is ${counter}. Going to sleep on condition variable...`);
        // Atomically unlocks stateMutex, sleeps, and re-locks stateMutex upon waking
        sync.wait(stageCond, stateMutex);
        print("[Consumer] Woke up! Re-acquired mutex. Checking condition again...");
    }

    print(`[Consumer] Target reached (${counter} >= ${TARGET_VALUE})! Processing complete.`);

    sync.unlock(stateMutex);
    print("[Consumer] Mutex unlocked. Exiting.");
});

// 3. The Notifier (Producer Thread)
const producerTid = task.create(() => {
    print("[Producer] Starting up. Beginning work simulation...");

    for (let i = 1; i <= TARGET_VALUE; i++) {
        sleep(1); // Simulate some work that takes time

        print(`[Producer] Work chunk ${i} done. Locking mutex to update state...`);
        sync.lock(stateMutex);

        counter = i;
        print(`[Producer] Updated counter to ${counter}.`);

        if (counter === TARGET_VALUE) {
            print("[Producer] Target reached! Broadcasting notification to condition variable.");
            sync.notify(stageCond, true); // Wake up all waiting threads
        }

        sync.unlock(stateMutex);
        print("[Producer] Mutex unlocked.");
    }

    print("[Producer] Work finished. Exiting.");
});

// Wait for both threads to finish their execution
task.join(consumerTid);
task.join(producerTid);

print("=== Sync Primitive Test Completed ===");