// Pure snapshot logic: keep the order stable until Alt is released.
function minimized(name) {
    return name === "special:minimized" || name.startsWith("special:minimized-");
}

function matches(client, entry) {
    // HyprlandToplevel.address omits 0x; snapshots use the IPC address throughout.
    return !!entry && client.address === entry.address && client.pid === entry.pid;
}

function snapshot(clients, active, workspace, config, history) {
    return clients.filter(c => {
        const name = c.workspace?.name ?? "";
        if (!c.address || !c.mapped || !c.class || c.hidden)
            return false;
        if (minimized(name))
            return config.includeMinimized;
        if (name.startsWith("special:") && name !== workspace)
            return false;
        return config.allWorkspaces || name === workspace || c.pinned;
    }).sort((a, b) => {
        if (a.address === active) return -1;
        if (b.address === active) return 1;
        const ai = history.indexOf(a.address);
        const bi = history.indexOf(b.address);
        const rank = c => c.focusHistoryID >= 0 ? c.focusHistoryID : 100000;
        return (ai < 0 ? 100000 : ai) - (bi < 0 ? 100000 : bi) || rank(a) - rank(b);
    }).map(c => ({address: c.address, pid: c.pid}));
}

function next(index, direction, length) {
    return length ? (index + direction + length) % length : -1;
}
