function resolveWorkspaceId(workspace, isScratchpad) {
  if (!workspace)
    return "";

  if (isScratchpad) {
    const scratchpadId = workspace.name || workspace.scratchpadName || workspace.id;
    return scratchpadId !== undefined && scratchpadId !== null ? scratchpadId : "";
  }

  const regularId = workspace.id !== undefined && workspace.id !== null ? workspace.id : (workspace.name || "");
  return regularId !== undefined && regularId !== null ? regularId : "";
}

if (typeof module !== "undefined") {
  module.exports = {
    resolveWorkspaceId,
  };
}
