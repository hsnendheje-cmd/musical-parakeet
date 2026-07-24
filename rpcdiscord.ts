import DiscordRPC = require("discord-rpc");

declare const process: any;

const clientId = "1519419543607312464";
const reconnectDelayMs = 5000;
const updateDelayMs = 15000;

let rpc: DiscordRPC.Client | null = null;
let startTimestamp = Math.floor(Date.now() / 1000);
let reconnectTimer: ReturnType<typeof setTimeout> | null = null;
let updateTimer: ReturnType<typeof setInterval> | null = null;
let connecting = false;

function log(message: string) {
    console.log(`[RPC] ${message}`);
}

function stopTimers() {
    if (reconnectTimer) {
        clearTimeout(reconnectTimer);
        reconnectTimer = null;
    }

    if (updateTimer) {
        clearInterval(updateTimer);
        updateTimer = null;
    }
}

function scheduleReconnect() {
    if (reconnectTimer) {
        return;
    }

    reconnectTimer = setTimeout(() => {
        reconnectTimer = null;
        connect();
    }, reconnectDelayMs);
}

async function setPresence() {
    if (!rpc) {
        return;
    }

    await rpc.setActivity({
        state: "N5.exe Mod Menu",
        details: "Animal Company",
        startTimestamp,
        largeImageKey: "n5_logo",
        largeImageText: "N5 Menu",
        buttons: [
            {
                label: "Download Our Menu",
                url: "https://discord.gg/n5mh"
            }
        ],
        instance: false
    });
}

async function connect() {
    if (connecting) {
        return;
    }

    connecting = true;
    stopTimers();
    rpc = new DiscordRPC.Client({ transport: "ipc" });

    rpc.on("ready", async () => {
        startTimestamp = Math.floor(Date.now() / 1000);
        log("Connected to Discord.");

        try {
            await setPresence();
            updateTimer = setInterval(() => {
                setPresence().catch((err: Error) => log(`Presence update failed: ${err.message}`));
            }, updateDelayMs);
        } catch (err) {
            log(`Presence update failed: ${(err as Error).message}`);
        }
    });

    rpc.on("disconnected", () => {
        log("Disconnected. Reconnecting in 5 seconds...");
        stopTimers();
        scheduleReconnect();
    });

    try {
        await rpc.login({ clientId });
    } catch (err) {
        const message = (err as Error).message || String(err);
        log(`Could not connect: ${message}`);
        log("Make sure Discord is open and logged in, then leave this window open.");
        scheduleReconnect();
    } finally {
        connecting = false;
    }
}

process.on("uncaughtException", (err) => {
    log(`Uncaught exception: ${err.message}`);
    scheduleReconnect();
});

process.on("unhandledRejection", (reason) => {
    log(`Unhandled rejection: ${reason instanceof Error ? reason.message : String(reason)}`);
    scheduleReconnect();
});

log("Starting Discord Rich Presence...");
connect();
