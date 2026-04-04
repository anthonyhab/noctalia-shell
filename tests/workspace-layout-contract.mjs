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

const strip = readContract("Modules/Bar/Widgets/Workspace/WorkspaceStrip.qml");

if (!strip.includes("spacing: root.metrics.pillGap")) {
  console.error("Expected WorkspaceStrip.qml to use metrics-driven pill spacing.");
  process.exit(1);
}

if (!strip.includes("Style.pixelAlignCenter(")) {
  console.error("Expected WorkspaceStrip.qml to use Style.pixelAlignCenter for snapped centering.");
  process.exit(1);
}
