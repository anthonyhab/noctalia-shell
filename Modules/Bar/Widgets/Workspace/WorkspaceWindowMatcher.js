function normalizeWorkspaceValue(value) {
  if (value === undefined || value === null)
    return "";
  return String(value);
}

function workspaceMatchesWindow(window, workspaceId, workspaceName) {
  if (!window)
    return false;

  const normalizedWorkspaceId = normalizeWorkspaceValue(workspaceId);
  const normalizedWorkspaceName = normalizeWorkspaceValue(workspaceName);
  const normalizedWindowId = normalizeWorkspaceValue(window.workspaceId);
  const normalizedWindowName = normalizeWorkspaceValue(window.workspaceName);

  if (normalizedWorkspaceId.length > 0 && normalizedWindowId.length > 0 && normalizedWorkspaceId === normalizedWindowId)
    return true;

  if (normalizedWorkspaceName.length > 0) {
    if (normalizedWindowName.length > 0 && normalizedWorkspaceName === normalizedWindowName)
      return true;
    if (normalizedWindowId.length > 0 && normalizedWorkspaceName === normalizedWindowId)
      return true;
  }

  return false;
}

if (typeof module !== "undefined") {
  module.exports = {
    normalizeWorkspaceValue,
    workspaceMatchesWindow,
  };
}
