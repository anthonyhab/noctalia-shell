import fs from "node:fs";
import path from "node:path";

function readContract(relativePath) {
  const filePath = path.resolve(relativePath);
  if (!fs.existsSync(filePath)) {
    console.error(`Expected ${relativePath} to exist.`);
    process.exit(1);
  }
  return fs.readFileSync(filePath, "utf8");
}

const workspace = readContract("Modules/Bar/Widgets/Workspace.qml");
const strip = readContract("Modules/Bar/Widgets/Workspace/WorkspaceStrip.qml");

if (!workspace.includes("WorkspaceComponents.WorkspaceStrip")) {
  console.error("Expected Workspace.qml to render the new WorkspaceStrip.");
  process.exit(1);
}

if (workspace.includes("WorkspaceComponents.WorkspaceCapsule")) {
  console.error("Expected Workspace.qml to stop rendering the legacy WorkspaceCapsule delegate directly.");
  process.exit(1);
}

if (!strip.includes("WorkspacePill")) {
  console.error("Expected WorkspaceStrip.qml to render WorkspacePill delegates.");
  process.exit(1);
}

if (!strip.includes("property string hoveredWorkspaceId")) {
  console.error("Expected WorkspaceStrip.qml to own hover mutual exclusion state.");
  process.exit(1);
}

if (!strip.includes("onHoverActivated")) {
  console.error("Expected WorkspaceStrip.qml to wire hover activation through the pill delegates.");
  process.exit(1);
}
