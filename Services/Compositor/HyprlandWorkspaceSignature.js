.pragma library

function buildSignature(workspaces, occupiedIds, toplevels) {
  const workspaceParts = [];
  const scratchpadParts = [];

  for (let i = 0; i < workspaces.length; i++) {
    const workspace = workspaces[i];
    const isScratchpad = (workspace.id < 0) || (workspace.name && workspace.name.startsWith("special:"));
    workspaceParts.push(
      `${workspace.id}:${workspace.active === true}:${workspace.focused === true}:${occupiedIds[workspace.id] === true}:${isScratchpad}`
    );
  }

  for (let i = 0; i < toplevels.length; i++) {
    const toplevel = toplevels[i];
    const workspace = toplevel && toplevel.workspace;
    if (!workspace) continue;

    const workspaceName = workspace.name || "";
    const isScratchpad = (workspace.id < 0) || workspaceName.startsWith("special:");
    if (!isScratchpad) continue;

    scratchpadParts.push(`${workspace.id}:${workspaceName}`);
  }

  scratchpadParts.sort();
  return workspaceParts.join(",") + "|" + scratchpadParts.join(",");
}
