import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);

function readContract(relativePath) {
  const filePath = path.resolve(relativePath);
  if (!fs.existsSync(filePath)) {
    console.error(`Expected ${relativePath} to exist.`);
    process.exit(1);
  }
  return fs.readFileSync(filePath, "utf8");
}

const pill = readContract("Modules/Bar/Widgets/Workspace/WorkspacePill.qml");
const helperPath = path.resolve("Modules/Bar/Widgets/Workspace/WorkspaceWindowSource.js");
const { deriveWorkspaceName, resolveLiveWorkspaceId } = require(helperPath);

if (resolveLiveWorkspaceId({ id: 4 }, "4", false) !== 4) {
  console.error("Expected live workspace lookup to preserve numeric regular workspace ids from workspaceModel.id.");
  process.exit(1);
}

if (resolveLiveWorkspaceId({ id: 7 }, "special:notes", true) !== "special:notes") {
  console.error("Expected scratchpads to keep the string workspace id for compositor matching.");
  process.exit(1);
}

if (resolveLiveWorkspaceId(null, "4", false) !== "4") {
  console.error("Expected live workspace lookup to fall back to the provided workspaceId when no model id exists.");
  process.exit(1);
}

if (deriveWorkspaceName({ scratchpadName: "special:music", name: "music" }, true) !== "special:music") {
  console.error("Expected scratchpad workspace names to prefer scratchpadName.");
  process.exit(1);
}

if (deriveWorkspaceName({ name: "4:web", id: 4 }, false) !== "4:web") {
  console.error("Expected regular workspace names to prefer workspaceModel.name.");
  process.exit(1);
}

if (!pill.includes("import \"WorkspaceWindowSource.js\" as WorkspaceWindowSource")) {
  console.error("Expected WorkspacePill.qml to import WorkspaceWindowSource for live workspace normalization.");
  process.exit(1);
}

if (!pill.includes("readonly property var liveWorkspaceId: WorkspaceWindowSource.resolveLiveWorkspaceId(workspaceModel, workspaceId, isScratchpad)")) {
  console.error("Expected WorkspacePill.qml to derive a liveWorkspaceId for compositor queries.");
  process.exit(1);
}

if (!pill.includes("readonly property string workspaceName: WorkspaceWindowSource.deriveWorkspaceName(workspaceModel, isScratchpad)")) {
  console.error("Expected WorkspacePill.qml to derive workspaceName through the shared workspace source helper.");
  process.exit(1);
}

const modelPreferredBeforeLiveSource = /const source = workspaceModel && workspaceModel\.windows \? workspaceModel\.windows : null;[\s\S]*?const sourceCount = modelCount\(source\);[\s\S]*?if \(sourceCount > 0\) \{[\s\S]*?workspaceWindows = sourceWindows;[\s\S]*?return;[\s\S]*?\}[\s\S]*?const nextWindows = \[\];[\s\S]*?const rawWindows = CompositorService\.getWindowsForWorkspace\(liveWorkspaceId\) \|\| \[\];/;
if (!modelPreferredBeforeLiveSource.test(pill)) {
  console.error("Expected WorkspacePill.qml to prefer populated workspaceModel.windows before querying the compositor with liveWorkspaceId.");
  process.exit(1);
}

const liveFallbackMatcher = /if \(nextWindows\.length === 0 && \(liveWorkspaceId !== \"\" \|\| workspaceName !== \"\"\)\) \{[\s\S]*?WorkspaceWindowMatcher\.workspaceMatchesWindow\(candidate, liveWorkspaceId, workspaceName\)[\s\S]*?\}/;
if (!liveFallbackMatcher.test(pill)) {
  console.error("Expected WorkspacePill.qml to fall back from getWindowsForWorkspace to matcher-based compositor window sourcing using liveWorkspaceId.");
  process.exit(1);
}
