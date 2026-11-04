for workspace = 1, 10 do
    hl.workspace_rule({
        workspace = tostring(workspace),
        monitor = LAPTOP_ONLY and MONITOR2 or (workspace <= 8 and MONITOR1 or MONITOR2),
        default = workspace == 1 or (not LAPTOP_ONLY and workspace == 9),
        persistent = true,
    })
end

-- Special app workspaces inherit the same gaps as the numbered desktops.
