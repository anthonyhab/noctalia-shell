function resolveLiveWorkspaceId(workspaceModel, workspaceId, isScratchpad) {
  if (workspaceModel && workspaceModel.id !== undefined && workspaceModel.id !== null && workspaceModel.id !== "")
    return workspaceModel.id;

  return workspaceId;
}

function deriveWorkspaceName(workspaceModel, isScratchpad) {
  if (!workspaceModel)
    return "";

  if (isScratchpad)
    return String(workspaceModel.scratchpadName || workspaceModel.name || "");

  return String(workspaceModel.name || workspaceModel.id || "");
}

if (typeof module !== "undefined") {
  module.exports = {
    deriveWorkspaceName,
    resolveLiveWorkspaceId,
  };
}
