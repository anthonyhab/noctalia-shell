import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);

const stripPath = path.resolve("Modules/Bar/Widgets/Workspace/WorkspaceStrip.qml");
const helperPath = path.resolve("Modules/Bar/Widgets/Workspace/WorkspaceStripNormalization.js");

if (!fs.existsSync(stripPath)) {
  console.error("Expected WorkspaceStrip.qml to exist.");
  process.exit(1);
}

if (!fs.existsSync(helperPath)) {
  console.error("Expected WorkspaceStripNormalization.js to exist.");
  process.exit(1);
}

const strip = fs.readFileSync(stripPath, "utf8");
const { resolveWorkspaceId } = require(helperPath);

if (resolveWorkspaceId({ id: 4 }, false) !== 4) {
  console.error("Expected regular workspaces to preserve numeric ids.");
  process.exit(1);
}

if (resolveWorkspaceId({ name: "special:notes" }, true) !== "special:notes") {
  console.error("Expected scratchpads to use their name when present.");
  process.exit(1);
}

if (resolveWorkspaceId({ scratchpadName: "notes" }, true) !== "notes") {
  console.error("Expected scratchpads to fall back to scratchpadName.");
  process.exit(1);
}

if (resolveWorkspaceId({}, false) !== "") {
  console.error("Expected missing regular workspace ids to normalize to an empty string.");
  process.exit(1);
}

if (resolveWorkspaceId({}, true) !== "") {
  console.error("Expected missing scratchpad workspace ids to normalize to an empty string.");
  process.exit(1);
}

if (!strip.includes("import \"WorkspaceStripNormalization.js\" as WorkspaceStripNormalization")) {
  console.error("Expected WorkspaceStrip.qml to import WorkspaceStripNormalization.");
  process.exit(1);
}

if (!strip.includes("\"workspaceId\": WorkspaceStripNormalization.resolveWorkspaceId(workspace, false)")) {
  console.error("Expected regular workspace entries to normalize workspaceId through the helper.");
  process.exit(1);
}

if (!strip.includes("\"workspaceId\": WorkspaceStripNormalization.resolveWorkspaceId(scratchpad, true)")) {
  console.error("Expected scratchpad entries to normalize workspaceId through the helper.");
  process.exit(1);
}
